use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr weaken);
use FSM::AST::Node;
use FSM::CoreAST;
use FSM::HDL::ASTFactorization;
use FSM::HDL::FlattenedDT;
my $json = JSON::PP->new->canonical;
my $has_api = FSM::HDL::ASTFactorization->can('intermediate_width_allocation_birth');
sub runtime_ref {FSM::AST::SignalRef->new($_[0])}
sub core_ref {FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name => $_[0], width => 8))}
sub binary {FSM::AST::BinaryOp->new($_[0] // '&', runtime_ref($_[1] // 'A'), runtime_ref($_[2] // 'B'))}
sub factor {
    my ($ast) = @_;
    my $f = FSM::HDL::ASTFactorization->new;
    $f->add_ast_expression($ast, 'first'); $f->add_ast_expression($ast, 'second');
    my $result = $f->analyze_and_factorize;
    my ($name) = grep {refaddr($result->{intermediate_signals}{$_}{ast}) == refaddr($ast)} keys %{$result->{intermediate_signals}};
    return ($f, $result, $name);
}
sub expected {{kind => 'binary_operand_max_candidate', operator => $_[0] // '&', source_names => $_[1] // ['A','B']}}
subtest 'actual unresolved candidate birth detaches without changing existing row shape' => sub {
    my ($f, $result, $name) = factor(binary());
    ok(defined $name, 'actual analysis allocates the repeated binary candidate');
    my $birth = eval {$f->intermediate_width_allocation_birth($name)};
    ok(!$@, 'factorizer exposes current unresolved birth') or diag $@;
    return unless $has_api;
    is_deeply($birth, expected(), 'actual allocator supplies binary max candidate intent');
    my $info = $result->{intermediate_signals}{$name};
    is_deeply([sort keys %$info], [sort qw(ast contexts structural_id usage_count width width_source)], 'ordinary candidate keys preserve');
    ok(!defined($info->{width}), 'birth leaves width unresolved');
    is($info->{width_source}, 'unresolved_factorization_ast', 'existing source label preserves');
    $birth->{source_names}[0] = 'FOREIGN';
    is_deeply($f->intermediate_width_allocation_birth($name), expected(), 'getter data deeply detaches');
    ok(eval {$json->encode($f->{_intermediate_width_allocation_births}); 1}, 'complete owner-local birth map is plain JSON');
    $info->{width} = 32; $info->{width_source} = 'cached_width';
    is_deeply($f->intermediate_width_allocation_birth($name), expected(), 'original unresolved birth remains distinct from a later independent cached floor');
    ok(!exists($f->intermediate_width_allocation_birth($name)->{selected_width}), 'birth supplies no selected policy or generic admission');
};
subtest 'canonical Core/runtime operators and duplicate ordered slots retain actual birth' => sub {
    plan skip_all => 'birth API absent' unless $has_api;
    for my $operator ('&','|','^') {
        for my $class ('FSM::AST::BinaryOp','FSM::CoreAST::BinaryOp') {
            my @refs = $class eq 'FSM::CoreAST::BinaryOp' ? (core_ref('B'),core_ref('A')) : (runtime_ref('B'),runtime_ref('A'));
            my ($f, undef, $name) = factor($class->new($operator,@refs));
            is_deeply($f->intermediate_width_allocation_birth($name), expected($operator,['B','A']), 'actual typed fresh allocator preserves opcode and operand order');
        }
    }
    my ($f, undef, $name) = factor(binary('|','A','A'));
    is_deeply($f->intermediate_width_allocation_birth($name), expected('|',['A','A']), 'duplicate source slots remain distinct ordered entries');
};
subtest 'opaque copied rows and foreign/stale actual identities cannot invent birth' => sub {
    plan skip_all => 'birth API absent' unless $has_api;
    my $plain = FSM::HDL::ASTFactorization->new;
    my $keys = join(',',sort keys %$plain);
    is($plain->intermediate_width_allocation_birth('absent'), undef, 'ordinary lookup supplies no candidate');
    is(join(',',sort keys %$plain),$keys,'ordinary getter adds no tracker');
    for my $invalid (undef, '', 'bad-name', []) {
        my $value;
        my $ok = eval {local $SIG{__WARN__} = sub {die @_}; $value = $plain->intermediate_width_allocation_birth($invalid); 1};
        ok($ok && !defined($value), 'invalid lookup withholds without warnings or mutation');
    }
    my ($f, $result, $name) = factor(binary());
    $plain->{intermediate_signals}{$name} = {%{$result->{intermediate_signals}{$name}}};
    is($plain->intermediate_width_allocation_birth($name),undef,'equal unresolved row has no actual allocator birth');
    $plain->{_intermediate_width_allocation_births} = $json->decode($json->encode($f->{_intermediate_width_allocation_births}));
    is($plain->intermediate_width_allocation_birth($name),undef,'copied capsule cannot borrow owner/entry identity');
    for my $mutate (
        sub {my($f,$n)=@_;$f->{intermediate_signals}{$n}={%{$f->{intermediate_signals}{$n}}}},
        sub {my($f,$n)=@_;$f->{intermediate_signals}{$n}{ast}=binary()},
        sub {my($f,$n)=@_;$f->{intermediate_signals}{$n}{ast}{operator}='|'},
        sub {my($f,$n)=@_;$f->{intermediate_signals}{$n}{ast}{left}=runtime_ref('A')},
        sub {my($f,$n)=@_;$f->{intermediate_signals}{$n}{structural_id}='foreign'},
        sub {my($f,$n)=@_;$f->{_intermediate_width_allocation_births}{$n}{record}{extra}=1},
    ) {
        my ($owner, undef, $allocated) = factor(binary());
        $mutate->($owner,$allocated);
        is($owner->intermediate_width_allocation_birth($allocated),undef,'divergent actual ownership/tree/reference/schema withholds');
    }
    my $core = FSM::CoreAST::BinaryOp->new('&',core_ref('A'),core_ref('B'));
    my ($owner, undef, $allocated) = factor($core);
    $core->left->{signal} = FSM::CoreAST::Signal->new(name=>'A',width=>8);
    is($owner->intermediate_width_allocation_birth($allocated),undef,'same-name replacement Core source cannot borrow actual source identity');
};
subtest 'unsupported roots stay unqualified and retained birth data owns no AST graph' => sub {
    plan skip_all => 'birth API absent' unless $has_api;
    my $slice = FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name=>'A',width=>8),slice=>[3,0]);
    for my $ast (
        FSM::CoreAST::BinaryOp->new('&',$slice,core_ref('B')),
        FSM::AST::BinaryOp->new('&',FSM::AST::Literal->new('3'),runtime_ref('B')),
        FSM::AST::BinaryOp->new('&',binary('|'),runtime_ref('B')),
        FSM::AST::BinaryOp->new('&',FSM::AST::SignalRef->new('A',is_fsm_state_next=>1),runtime_ref('B')),
        binary('&&'),
    ) {
        my ($f, undef, $name) = factor($ast);
        ok(!defined($name) || !defined($f->intermediate_width_allocation_birth($name)), 'unsupported actual root creates no binary whole-reference birth');
    }
    my ($weak_f,$weak_ast,$retained);
    {
        my $ast = binary();my ($f, undef, $name) = factor($ast);
        $weak_f=$f;$weak_ast=$ast;weaken($weak_f);weaken($weak_ast);
        $retained=$json->decode($json->encode($f->{_intermediate_width_allocation_births}));
    }
    ok(!defined($weak_f) && !defined($weak_ast), 'retained plain birth state releases actual factorizer and AST owners');
};
subtest 'actual raw-Core backend keeps birth distinct after ordinary selected-width normalization' => sub {
    plan skip_all => 'birth API absent' unless $has_api;
    for my $width (1,8) {
        for my $operator ('&','|','^') {
            my %signals = map {$_ => FSM::CoreAST::Signal->new(name=>$_,width=>/^[AB]$/ ? $width : 1)} qw(A B DATA OTHER);
            my $condition = FSM::CoreAST::BinaryOp->new($operator,
                FSM::CoreAST::SignalRef->new($signals{A}), FSM::CoreAST::SignalRef->new($signals{B}));
            my @actions = map {FSM::CoreAST::Assignment->new(target=>FSM::CoreAST::SignalRef->new($signals{$_}),
                source=>FSM::CoreAST::Literal->new('1'))} qw(DATA OTHER);
            my $branch = FSM::CoreAST::ConditionalBranch->new(condition=>$condition,
                branches=>[{condition=>$condition,actions=>\@actions}]);
            my $tree = FSM::CoreAST::DecisionTree->new(name=>'idle',elements=>[$branch,
                FSM::CoreAST::StateTransitionFSM->new(target_state=>'idle')]);
            my $module = FSM::CoreAST::FSMModule->new(name=>'raw_birth',signals=>\%signals,
                states=>[FSM::CoreAST::State->new(name=>'idle',decision_trees=>[$tree])]);
            my $backend = FSM::HDL::FlattenedDT->new;
            my $hdl = $backend->generate_systemverilog($module);
            like($hdl,qr/assign \w+ = A \Q$operator\E B; \/\/ Source: ast_factorization/,
                'actual native path retains binary helper expression');
            my $factorizer = $backend->{ast_factorizer};
            my @births = grep {$_ && $_->{operator} eq $operator && $json->encode($_->{source_names}) eq '["A","B"]'}
                map {$factorizer->intermediate_width_allocation_birth($_)} keys %{$factorizer->{intermediate_signals}};
            is(scalar @births,1,'actual normalized backend retains its independently anchored original candidate birth');
            ok(!exists($births[0]{selected_width}), 'native normalization alone supplies no selected allocation policy');
        }
    }
};
done_testing();
