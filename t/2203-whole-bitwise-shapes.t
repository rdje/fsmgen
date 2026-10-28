use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use FSM::CoreAST;
use FSM::AST::Node;
use FSM::HDL::ASTFactorization;
use FSM::HDL::FlattenedDT;
use FSM::IntermediateWidthAllocationSupport;
my $json = JSON::PP->new->canonical;
my $has_shape = FSM::IntermediateWidthAllocationSupport->can('binary_whole_signal_shape');
sub core_ref {FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name => $_[0], width => 8))}
sub runtime_ref {FSM::AST::SignalRef->new($_[0])}
sub shape {{operator => $_[0], source_names => $_[1] // ['A','B']}}
subtest 'typed binary whole-reference shapes are detached and keep ordered duplicates' => sub {
    my $ast = FSM::AST::BinaryOp->new('&', runtime_ref('A'), runtime_ref('B'));
    my $value = eval {FSM::IntermediateWidthAllocationSupport->binary_whole_signal_shape($ast)};
    ok(!$@, 'shared typed shape authority exists') or diag $@;
    return unless $has_shape;
    for my $operator ('&','|','^') {
        for my $class ('FSM::AST::BinaryOp', 'FSM::CoreAST::BinaryOp', 'FSM::HDL::SubstitutedBinaryOp') {
            my @operands = $class eq 'FSM::CoreAST::BinaryOp' ? (core_ref('B'), core_ref('A')) : (runtime_ref('B'), runtime_ref('A'));
            my $node = $class eq 'FSM::HDL::SubstitutedBinaryOp'
                ? $class->new(operator => $operator, left => $operands[0], right => $operands[1])
                : $class->new($operator, @operands);
            is_deeply(FSM::IntermediateWidthAllocationSupport->binary_whole_signal_shape($node), shape($operator,['B','A']),
                'actual typed operator families retain both ordered slots');
        }
    }
    my $duplicate = FSM::AST::BinaryOp->new('|', runtime_ref('A'), runtime_ref('A'));
    my $record = FSM::IntermediateWidthAllocationSupport->binary_whole_signal_shape($duplicate);
    $record->{source_names}[0] = 'WRONG';
    is_deeply(FSM::IntermediateWidthAllocationSupport->binary_whole_signal_shape($duplicate), shape('|',['A','A']),
        'duplicate slots preserve and returned arrays detach');
    ok(eval {$json->encode($value); 1}, 'result is plain data without AST/Signal owners');
};
subtest 'sliced Core defining AST cannot borrow an unsliced runtime origin' => sub {
    my $dt = FSM::HDL::FlattenedDT->new;
    my $recovery = $dt->{backend_sv_intermediate_recovery_support};
    my $slice = FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name => 'A', width => 8), slice => [3,0]);
    my $runtime = FSM::AST::BinaryOp->new('&', runtime_ref('A'), runtime_ref('B'));
    my $defining = FSM::CoreAST::BinaryOp->new('&', $slice, core_ref('B'));
    my $text = $dt->{enable_graph_ast_support}->ast_to_systemverilog($runtime);
    is($recovery->binary_bitwise_origin('RESULT', {ast => $defining, runtime_ast => $runtime}, $text), undef,
        'actual binary origin refuses sliced Core association despite matching bare names/text');
    my $unary_runtime = FSM::AST::UnaryOp->new('^', runtime_ref('A'));
    my $unary_defining = FSM::CoreAST::UnaryOp->new(operator => '^', operand => $slice);
    my $unary_text = $dt->{enable_graph_ast_support}->ast_to_systemverilog($unary_runtime);
    is($recovery->scalar_reduction_origin('RESULT', {ast => $unary_defining, runtime_ast => $unary_runtime}, $unary_text), undef,
        'actual scalar origin also refuses sliced Core association');
};
subtest 'actual compatible intermediate references require only their published typed interface' => sub {
    my $dt = FSM::HDL::FlattenedDT->new;
    my $reference = FSM::HDL::IntermediateSignalRef->new(signal_name => 'nested_helper');
    my $runtime = FSM::AST::BinaryOp->new('&', $reference, runtime_ref('B'));
    my $text = $dt->{enable_graph_ast_support}->ast_to_systemverilog($runtime);
    my $origin = eval {$dt->{backend_sv_intermediate_recovery_support}->binary_bitwise_origin(
        'RESULT', {ast => $runtime, runtime_ast => $runtime}, $text)};
    ok(!$@, 'origin recovery does not call absent state/signal methods on compatible reference') or diag $@;
    is_deeply($origin, {kind => 'binary_bitwise', %{shape('&',['nested_helper','B'])}},
        'actual compatible whole name survives without inventing Signal identity or allocation policy');
};
subtest 'state, slice, literal, logical, compound and invalid names cannot assert a whole shape' => sub {
    plan skip_all => 'shared shape authority absent' unless $has_shape;
    my $slice = FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name => 'A', width => 8), slice => [3,0]);
    for my $left ($slice, FSM::AST::SignalRef->new('A',is_fsm_state_next => 1),
        FSM::AST::SignalRef->new('A',is_fsm_state_register => 1), runtime_ref('A[3:0]'),
        runtime_ref('bad-name'), FSM::AST::Literal->new('3'), FSM::CoreAST::SignalRef->new(undef),
        FSM::AST::BinaryOp->new('|',runtime_ref('A'),runtime_ref('B'))) {
        is(FSM::IntermediateWidthAllocationSupport->binary_whole_signal_shape(
            FSM::AST::BinaryOp->new('&',$left,runtime_ref('B'))), undef, 'non-whole/invalid operand is withheld');
    }
    is(FSM::IntermediateWidthAllocationSupport->binary_whole_signal_shape(
        FSM::AST::BinaryOp->new('&&',runtime_ref('A'),runtime_ref('B'))), undef, 'logical operation supplies no bitwise shape');
};
done_testing();
