use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr weaken);
use Lispish;
use FSM::AST::Node;
use FSM::CoreAST;
use FSM::HDL::ASTFactorization;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::Backend::VerilogFamily::DeclarationCapture;

my $json = JSON::PP->new->canonical;
my $has_api = FSM::HDL::ASTFactorization->can('intermediate_width_graph_birth');
sub signal {return FSM::AST::SignalRef->new($_[0])}
sub expression {
    return FSM::AST::BinaryOp->new('+',
        FSM::AST::BinaryOp->new('+', signal('A'), signal('B')), signal('C'));
}
sub expected {
    return {kind => 'arithmetic_graph_candidate', expression_tree =>
        ['+', ['+', ['signal','A'], ['signal','B']], ['signal','C']]};
}
sub factor {
    my ($ast) = @_;
    my $f = FSM::HDL::ASTFactorization->new;
    $f->add_ast_expression($ast, 'first');
    $f->add_ast_expression($ast, 'second');
    my $result = $f->analyze_and_factorize;
    my ($name) = grep {refaddr($result->{intermediate_signals}{$_}{ast}) == refaddr($ast)}
        keys %{$result->{intermediate_signals}};
    return ($f, $result, $name);
}

subtest 'actual fresh original tree survives owned typed substitution with no selected policy' => sub {
    my ($f, $result, $name) = factor(expression());
    my $birth = eval {$f->intermediate_width_graph_birth($name)};
    ok(!$@, 'factorizer exposes separate current graph birth') or diag $@;
    return unless $has_api;
    is_deeply($birth, expected(), 'fresh nested allocation records the ordered original arithmetic tree');
    is($f->intermediate_width_allocation_birth($name), undef, 'whole-reference API does not widen to graph birth');
    my $row = $result->{intermediate_signals}{$name};
    ok(!defined($row->{width}), 'original graph birth precedes numeric selection');
    my @keys = sort keys %$row;
    $f->substitute_expressions_with_intermediate_signals($f->{ast_expressions});
    isa_ok($row->{ast}, 'FSM::HDL::SubstitutedBinaryOp');
    isa_ok($row->{ast}->left, 'FSM::HDL::IntermediateSignalRef');
    is_deeply($f->intermediate_width_graph_birth($name), expected(), 'owned substitution retains original tree and current edge ownership');
    is_deeply([sort keys %$row], \@keys, 'candidate metadata schema remains unchanged');
    $birth->{expression_tree}[1][1][1] = 'WRONG';
    is_deeply($f->intermediate_width_graph_birth($name), expected(), 'public diagnostic tree deeply detaches');
    ok(eval {$json->encode($f->{_intermediate_width_graph_births}); 1}, 'complete owner-local capsule map is plain JSON');
    $row->{width} = 32;
    $row->{width_source} = 'independent_floor';
    is_deeply($f->intermediate_width_graph_birth($name), expected(), 'historical unresolved birth imposes no later width equality');
    is(FSM::IntermediateWidthGraphBirthSupport->prepare_birth(factorizer => $f, signal_name => $name), undef,
        'selected numeric state cannot create a new original birth');
};

subtest 'canonical operations Core ownership and deeper dependency trees retain order' => sub {
    plan skip_all => 'graph birth API absent' unless $has_api;
    for my $operator ('+', '-', '*', '/', '%') {
        my $ast = FSM::AST::BinaryOp->new($operator, signal('C'),
            FSM::AST::BinaryOp->new('+', signal('A'), signal('A')));
        my ($f, undef, $name) = factor($ast);
        $f->substitute_expressions_with_intermediate_signals($f->{ast_expressions});
        is_deeply($f->intermediate_width_graph_birth($name),
            {kind => 'arithmetic_graph_candidate', expression_tree =>
                [$operator, ['signal','C'], ['+', ['signal','A'], ['signal','A']]]},
            'operator order and duplicate source slots preserve');
    }
    my $ast = FSM::AST::BinaryOp->new('+', signal('A'), FSM::AST::BinaryOp->new('+', signal('B'),
        FSM::AST::BinaryOp->new('*', signal('C'), signal('D'))));
    my ($f, undef, $name) = factor($ast);
    $f->substitute_expressions_with_intermediate_signals($f->{ast_expressions});
    is_deeply($f->intermediate_width_graph_birth($name),
        {kind => 'arithmetic_graph_candidate', expression_tree => ['+', ['signal','A'],
            ['+', ['signal','B'], ['*', ['signal','C'], ['signal','D']]]]},
        'parent original tree survives multiple actual generated-child levels');
    my %signals = map {$_ => FSM::CoreAST::Signal->new(name => $_, width => 8)} qw(A B C);
    my $core = FSM::CoreAST::BinaryOp->new('+', FSM::CoreAST::BinaryOp->new('+',
        FSM::CoreAST::SignalRef->new($signals{A}), FSM::CoreAST::SignalRef->new($signals{B})),
        FSM::CoreAST::SignalRef->new($signals{C}));
    my ($owner, undef, $root) = factor($core);
    $owner->substitute_expressions_with_intermediate_signals($owner->{ast_expressions});
    is_deeply($owner->intermediate_width_graph_birth($root), expected(), 'actual Core source identities retain through typed substitution');
    $core->left->left->{signal} = FSM::CoreAST::Signal->new(name => 'A', width => 8);
    is($owner->intermediate_width_graph_birth($root), undef, 'same-name replacement Core source revokes dependent lineage');
};

subtest 'only the actual mapped semantic substitution can advance original ownership' => sub {
    plan skip_all => 'graph birth API absent' unless $has_api;
    my $ast = expression();
    my ($f, undef, $name) = factor($ast);
    my %mapping = map {$f->{intermediate_signals}{$_}{structural_id} => $_} keys %{$f->{intermediate_signals}};
    my $new = $f->substitute_ast_recursively($ast, \%mapping, $name);
    my %args = (factorizer => $f, signal_name => $name,
        holder => $f->_current_intermediate_width_graph_birth($name), original_ast => $ast,
        substituted_ast => $new, mapping => \%mapping);
    ok(FSM::IntermediateWidthGraphBirthSupport->prepare_substitution(%args), 'actual mapped transformation yields pending plain state');
    is(FSM::IntermediateWidthGraphBirthSupport->prepare_substitution(%args, mapping => {}), undef,
        'printed generated reference without its actual mapping supplies no transition');
    my $wrong = FSM::HDL::SubstitutedBinaryOp->new(operator => '+', left => $new->left, right => signal('B'));
    is(FSM::IntermediateWidthGraphBirthSupport->prepare_substitution(%args, substituted_ast => $wrong), undef,
        'same-width wrong operand cannot borrow mapped child lineage');
    $f->{intermediate_signals}{$name}{width} = 8;
    is(FSM::IntermediateWidthGraphBirthSupport->prepare_substitution(%args), undef,
        'later selected numeric state cannot advance unresolved ownership');
    my ($cyclic, undef, $root) = factor(expression());
    my $root_ast = $cyclic->{intermediate_signals}{$root}{ast};
    my $left = $root_ast->left;
    $root_ast->{left} = $root_ast;
    is($cyclic->intermediate_width_graph_birth($root), undef, 'cyclic actual AST withholds without recursion');
    $root_ast->{left} = $left;
};

subtest 'copied rows capsules and changed typed dependencies cannot attest original ownership' => sub {
    plan skip_all => 'graph birth API absent' unless $has_api;
    for my $change (
        sub {$_[0]{intermediate_signals}{$_[1]} = {%{$_[0]{intermediate_signals}{$_[1]}}}},
        sub {$_[0]{intermediate_signals}{$_[1]}{ast} = expression()},
        sub {$_[0]{intermediate_signals}{$_[1]}{structural_id} = 'FOREIGN'},
        sub {$_[0]{_intermediate_width_graph_births}{$_[1]}{record}{extra} = 1},
    ) {
        my ($f, undef, $name) = factor(expression());
        $change->($f, $name);
        is($f->intermediate_width_graph_birth($name), undef, 'divergent original owner/tree/schema withholds');
    }
    my ($f, $result, $name) = factor(expression());
    my $other = FSM::HDL::ASTFactorization->new;
    $other->{intermediate_signals}{$name} = {%{$result->{intermediate_signals}{$name}}};
    $other->{_intermediate_width_graph_births} = $json->decode($json->encode($f->{_intermediate_width_graph_births}));
    is($other->intermediate_width_graph_birth($name), undef, 'foreign owner cannot borrow a copied original capsule');
    $f->substitute_expressions_with_intermediate_signals($f->{ast_expressions});
    my $child = $f->{intermediate_signals}{$name}{ast}->left->signal_name;
    $f->{intermediate_signals}{$child} = {%{$f->{intermediate_signals}{$child}}};
    is($f->intermediate_width_graph_birth($name), undef, 'same-width copied child entry revokes the actual generated edge');
};

subtest 'ordinary and unsupported lookups create no graph tracker or owner retention' => sub {
    plan skip_all => 'graph birth API absent' unless $has_api;
    my $plain = FSM::HDL::ASTFactorization->new;
    my @keys = sort keys %$plain;
    for my $name (undef, '', 'bad-name', [], 'absent') {
        my $value;
        ok(eval {local $SIG{__WARN__} = sub {die @_}; $value = $plain->intermediate_width_graph_birth($name); 1}
            && !defined($value), 'invalid or absent lookup withholds without warning');
    }
    is_deeply([sort keys %$plain], \@keys, 'ordinary getter creates no tracking field');
    for my $ast (
        FSM::AST::BinaryOp->new('+', signal('A'), signal('B')),
        FSM::AST::BinaryOp->new('+', signal('A'), FSM::AST::BinaryOp->new('*', signal('B'), FSM::AST::Literal->new('3'))),
        FSM::AST::BinaryOp->new('+', signal('A'), FSM::AST::BinaryOp->new('&', signal('B'), signal('C'))),
        FSM::AST::UnaryOp->new('!', expression()),
    ) {
        my ($f, undef, $name) = factor($ast);
        ok(!defined($name) || !defined($f->intermediate_width_graph_birth($name)), 'non-graph or unsupported original tree gets no arithmetic graph birth');
    }
    my ($weak_f, $weak_ast, $retained);
    {
        my $ast = expression();
        my ($f, undef, $name) = factor($ast);
        $f->substitute_expressions_with_intermediate_signals($f->{ast_expressions});
        $weak_f = $f; $weak_ast = $ast;
        weaken($weak_f); weaken($weak_ast);
        $retained = $f->{_intermediate_width_graph_births};
    }
    ok(!defined($weak_f) && !defined($weak_ast), 'retained graph capsules own no factorizer or original AST graph');
};

subtest 'real source generation retains graph birth while HDL and completed policy remain unchanged' => sub {
    plan skip_all => 'graph birth API absent' unless $has_api;
    for my $width (1, 8) {
        my $source = "(?fsm:graph_birth (+params (W $width))"
            . ' (+size (A (param W)) (B (param W)) (C (param W)) (DATA 1) (OTHER 1))'
            . ' (idle (<(+ A B C) (= (DATA 1)) (= (OTHER 1))) (-> idle)))';
        my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$source));
        my $ctx = FSM::HDL::FlattenedDT->new;
        my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
        my $hdl;
        {local $ctx->{declared_width_declaration_capture} = $capture; $hdl = $ctx->generate_systemverilog($module)}
        my $name = 'A_plus_B_plus_C';
        is_deeply($ctx->{ast_factorizer}->intermediate_width_graph_birth($name), expected(), 'real original ownership survives collection and numeric selection');
        my $range = $width == 1 ? '' : '[7:0] ';
        like($hdl, qr/^  wire \Q$range$name\E;$/m, 'outer graph HDL remains numeric before graph inference/range proof');
        ok(!exists($capture->snapshot->{target_intermediates}{$name}{width_allocation}), 'birth alone publishes no graph allocation event');
    }
};
done_testing();
