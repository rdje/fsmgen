use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use FSM::CoreAST;
use FSM::HDL::FlattenedDT;
use FSM::Synthesis::EnableGraph::CaptureSupport;

my $json = JSON::PP->new->canonical;
my $capture = FSM::Synthesis::EnableGraph::CaptureSupport->new(flattened_dt => {});
sub reference {FSM::CoreAST::SignalRef->new($_[0])}
sub binary {FSM::CoreAST::BinaryOp->new(@_)}
sub literal {FSM::CoreAST::Literal->new($_[0])}
sub signals {my ($width) = @_; return {map {$_ => FSM::CoreAST::Signal->new(name => $_, width => /^[AB]$/ ? $width : 1)} qw(A B DATA OTHER)}}
sub module {
    my ($signals, $condition) = @_;
    my @actions = map {FSM::CoreAST::Assignment->new(target => reference($signals->{$_}), source => literal('1'))} qw(DATA OTHER);
    my $branch = FSM::CoreAST::ConditionalBranch->new(condition => $condition,
        branches => [{condition => $condition, actions => \@actions}]);
    my $dt = FSM::CoreAST::DecisionTree->new(name => 'idle', elements => [$branch,
        FSM::CoreAST::StateTransitionFSM->new(target_state => 'idle')]);
    return FSM::CoreAST::FSMModule->new(name => 'core_binary_guard', signals => $signals,
        states => [FSM::CoreAST::State->new(name => 'idle', decision_trees => [$dt])]);
}
sub shape {
    my ($node) = @_;
    return ['signal', $node->signal->name, $node->signal->width] if $node->isa('FSM::CoreAST::SignalRef');
    return ['literal', $node->value, $node->width, $node->radix] if $node->isa('FSM::CoreAST::Literal');
    return [$node->operator, shape($node->operand)] if $node->isa('FSM::CoreAST::UnaryOp');
    return [$node->operator, shape($node->left), shape($node->right)];
}
sub snapshot {
    my ($m, $condition) = @_;
    return $json->encode([shape($condition), $m->parameters, $m->parameter_default_sources,
        $m->parameter_default_bindings, {map {my $s = $m->signals->{$_}; $_ => [$s->width, $s->signed, $s->type,
            $s->declared_width_source, $s->declared_width_binding, $s->declared_width_requirements]} keys %{$m->signals}}]);
}
sub evaluate {
    my ($ast, $a, $b) = @_;
    return $ast->name eq 'A' ? $a : $b if $ast->isa('FSM::AST::SignalRef');
    return 0 + $ast->value if $ast->isa('FSM::AST::Literal');
    return evaluate($ast->operand, $a, $b) ? 0 : 1 if $ast->isa('FSM::AST::UnaryOp') && $ast->operator eq '!';
    my ($left, $right) = (evaluate($ast->left, $a, $b), evaluate($ast->right, $a, $b));
    my $op = $ast->operator;
    return $left & $right if $op eq '&' || $op eq 'and';
    return $left | $right if $op eq '|' || $op eq 'or';
    return $left ^ $right if $op eq '^' || $op eq 'xor';
    return $left && $right ? 1 : 0 if $op eq '&&';
    return $left || $right ? 1 : 0 if $op eq '||';
    return $left == $right ? 1 : 0 if $op eq '==';
    return $left != $right ? 1 : 0 if $op eq '!=';
    die "unexpected captured operation $op";
}

subtest 'actual Core binary symbols preserve distinct vector and logical values recursively' => sub {
    my %truth = (
        1 => {'&' => [0,0,0,1], '|' => [0,1,1,1], '^' => [0,1,1,0], '&&' => [0,0,0,1], '||' => [0,1,1,1]},
        8 => {'&' => [0,2,0,1], '|' => [3,2,128,3], '^' => [3,0,128,2], '&&' => [1,1,0,1], '||' => [1,1,1,1]},
    );
    my %aliases = (and => '&', or => '|', xor => '^');
    for my $width (1,8) {
        my $s = signals($width); my @pairs = $width == 1 ? ([0,0],[0,1],[1,0],[1,1]) : ([1,2],[2,2],[0,128],[1,3]);
        for my $op ('&','|','^','&&','||','and','or','xor') {
            my $core = binary($op, reference($s->{A}), reference($s->{B}));
            my $before = $json->encode(shape($core));
            my $ast = $capture->convert_condition_to_ast($core);
            is($ast->operator, $op, 'the actual authored binary operation survives capture');
            is_deeply([map {evaluate($ast, @$_)} @pairs], $truth{$width}{$aliases{$op} // $op},
                'literal independent value table distinguishes bitwise results from logical truth');
            is($json->encode(shape($core)), $before, 'capture preserves complete recursive caller expression and JSON kinds');
        }
    }
};

subtest 'nested comparisons and recursive logical negation retain actual bitwise values' => sub {
    my $s = signals(8);
    for my $case (
        ['|', '==', '3', 0, [1,0,0,1]],
        ['||', '==', '3', 0, [0,0,0,0]],
        ['&', '==', '0', 0, [1,0,1,0]],
        ['&', '==', '0', 1, [0,1,0,1]],
    ) {
        my ($op,$compare,$value,$negative,$expected) = @$case;
        # Unsized decimal isolates opcode semantics; typed literal capture has
        # its own immediate owner and does not supply this oracle.
        my $core = binary($compare, binary($op, reference($s->{A}), reference($s->{B})), literal($value));
        $core = FSM::CoreAST::UnaryOp->new(operator => '!', operand => $core) if $negative;
        my $ast = $capture->convert_condition_to_ast($core);
        is_deeply([map {evaluate($ast, @$_)} ([1,2],[2,2],[0,128],[1,3])], $expected,
            'complete nested truth matches independent literal controls');
    }
};

subtest 'public Core constructors and backend emit actual vector helper ranges and whole-value selectors' => sub {
    my %names = ('&' => 'A_and_B', '|' => 'A_or_B', '^' => 'A_op_B', and => 'A_op_B', or => 'A_op_B', xor => 'A_op_B');
    my %symbols = (and => '&', or => '|', xor => '^');
    for my $width (1,8) {
        for my $op ('&','|','^','and','or','xor') {
            my $s = signals($width); my $core = binary($op, reference($s->{A}), reference($s->{B}));
            my $m = module($s,$core); my $before = snapshot($m,$core);
            my $dt = FSM::HDL::FlattenedDT->new(debug => 0); my $hdl = $dt->generate_systemverilog($m);
            my $name = $names{$op}; my $symbol = $symbols{$op} // $op;
            my $range = $width == 1 ? '' : '[7:0] ';
            like($hdl, qr/^  wire \Q$range$name\E;$/m, 'complete actual helper declaration retains vector result width');
            like($hdl, qr/^  assign \Q$name\E = A \Q$symbol\E B; \/\/ Source: ast_factorization$/m,
                'complete actual helper expression preserves bitwise operation and published aliases');
            my $gate = $width == 1 ? '&' : '&&';
            for my $target ('data','other') {
                like($hdl, qr/^  assign idle_\Q$target\E_1_en = idle_en \Q$gate\E \Q$name\E; /m,
                    'actual output selector uses the complete intermediate truth');
            }
            is(snapshot($m,$core), $before, 'complete actual caller widths/captures/recursive expression retain JSON kinds');
            (my $stable = $hdl) =~ s{^// Date:.*\n}{}m;
            (my $again = $dt->generate_systemverilog($m)) =~ s{^// Date:.*\n}{}m;
            is($again, $stable, 'backend reuse preserves the complete native product apart from Date');
        }
    }
};

subtest 'public nested OR comparison and ordinary logical native products stay distinct' => sub {
    for my $op ('|','||') {
        my $s = signals(8); my $value = binary($op, reference($s->{A}), reference($s->{B}));
        my $condition = binary('==',$value,literal('3')); my $m = module($s,$condition);
        my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($m);
        like($hdl, qr/^  assign A_or_B = A \Q$op\E B; \/\/ Source: ast_factorization$/m,
            'native nested predicate preserves bitwise or logical value producer');
        like($hdl, qr/^  assign A_or_B_eq_const_3 = A_or_B == 3; \/\/ Source: ast_factorization$/m,
            'native comparison retains its actual unsized decimal operand');
    }
};
done_testing();
