use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr weaken);
use Lispish;
use FSM::CoreAST;
use FSM::AST::Node;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::ASTFactorization;
use FSM::HDL::FlattenedDT;

my $json = JSON::PP->new->canonical;
my $has_api = FSM::HDL::ASTFactorization->can('concatenation_width_birth');
sub reference { FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name => $_[0], width => $_[1] // 8)) }
sub concat { FSM::CoreAST::Concatenation->new(@_) }
sub factor {
    my ($ast) = @_;
    my $factorizer = FSM::HDL::ASTFactorization->new;
    $factorizer->add_ast_expression($ast, 'first');
    $factorizer->add_ast_expression($ast, 'second');
    my $result = $factorizer->analyze_and_factorize;
    my ($name) = grep { refaddr($result->{intermediate_signals}{$_}{ast}) == refaddr($ast) }
        keys %{$result->{intermediate_signals}};
    return ($factorizer, $name);
}
sub birth { return eval { $_[0]->concatenation_width_birth($_[1]) } }
sub expected { return {kind => 'concatenation_sum_candidate', expression_tree => ['concat', @_]} }

subtest 'actual fresh candidates preserve complete ordered typed occurrences and raw literals' => sub {
    ok($has_api, 'actual allocator exposes concatenation birth') or return;
    my $a = reference('A');
    my $b = reference('B', 1);
    my $literal = FSM::CoreAST::Literal->new('0101', width => 4, radix => 'binary');
    my $unknown = FSM::CoreAST::Literal->new('7');
    my @cases = (
        [concat($a, $b), expected(['signal', 'A'], ['signal', 'B'])],
        [concat($b, $a, $a), expected(['signal', 'B'], ['signal', 'A'], ['signal', 'A'])],
        [concat($a, concat($literal, $b)), expected(['signal', 'A'],
            ['concat', ['literal', {value => '0101', width => 4, radix => 'binary'}], ['signal', 'B']])],
        [concat($a, $unknown), expected(['signal', 'A'],
            ['literal', {value => '7', width => undef, radix => 'decimal'}])],
        [concat(FSM::AST::SignalRef->new('R'), $a), expected(['signal', 'R'], ['signal', 'A'])],
    );
    for my $case (@cases) {
        my ($ast, $expected) = @$case;
        my $text = $ast->to_systemverilog;
        my ($factorizer, $name) = factor($ast);
        ok(defined $name, 'actual analysis allocates the repeated concat');
        is_deeply(birth($factorizer, $name), $expected, 'ordered source tree preserves every occurrence and independent field');
        my $entry = $factorizer->{intermediate_signals}{$name};
        is_deeply([sort keys %$entry], [sort qw(ast structural_id usage_count contexts width width_source)],
            'metadata does not change candidate row schema');
        ok(!defined($entry->{width}), 'candidate width remains unknown');
        $entry->{width} = 100; $entry->{width_source} = 'cached_width';
        is_deeply(birth($factorizer, $name), $expected, 'independent later width cannot rewrite original birth');
        is($ast->to_systemverilog, $text, 'caller AST and literal spelling preserve');
        my $copy = birth($factorizer, $name);
        $copy->{expression_tree}[1] = ['signal', 'FOREIGN'];
        is_deeply(birth($factorizer, $name), $expected, 'getter deeply detaches nested data');
        ok(eval {$json->encode($factorizer->{_concatenation_width_births}); 1}, 'all capsule state is plain JSON data');
        is($factorizer->intermediate_width_allocation_birth($name), undef, 'sum cannot borrow a binary maximum birth');
        is($factorizer->intermediate_width_graph_birth($name), undef, 'sum cannot borrow an arithmetic graph birth');
    }
};

subtest 'copied foreign stale and malformed ownership cannot reconstruct a birth' => sub {
    ok($has_api, 'current lookup API exists') or return;
    my $plain = FSM::HDL::ASTFactorization->new;
    my $before = [sort keys %$plain];
    for my $invalid (undef, '', 'bad-name', [], {}, 'absent') {
        my ($value, $error);
        { local $SIG{__WARN__} = sub {die @_}; eval {$value = $plain->concatenation_width_birth($invalid); 1} or $error = $@; }
        is($error, undef, 'invalid lookup is silent');
        is($value, undef, 'invalid lookup withholds');
    }
    is_deeply([sort keys %$plain], $before, 'ordinary lookup creates no tracking state');
    my ($factorizer, $name) = factor(concat(reference('A'), reference('B')));
    $plain->{intermediate_signals}{$name} = {%{$factorizer->{intermediate_signals}{$name}}};
    is(birth($plain, $name), undef, 'equal unresolved row has no allocator authority');
    $plain->{_concatenation_width_births} = $json->decode($json->encode($factorizer->{_concatenation_width_births}));
    is(birth($plain, $name), undef, 'foreign capsule cannot borrow allocator and row identity');
    for my $mutate (
        sub {my ($f,$n)=@_; $f->{intermediate_signals}{$n} = {%{$f->{intermediate_signals}{$n}}}},
        sub {my ($f,$n)=@_; $f->{intermediate_signals}{$n}{ast} = concat(reference('A'),reference('B'))},
        sub {my ($f,$n)=@_; $f->{intermediate_signals}{$n}{structural_id} = 'changed'},
        sub {my ($f,$n)=@_; @{$f->{intermediate_signals}{$n}{ast}{operands}} = reverse @{$f->{intermediate_signals}{$n}{ast}{operands}}},
        sub {my ($f,$n)=@_; $f->{intermediate_signals}{$n}{ast}{operands}[0] = reference('A')},
        sub {my ($f,$n)=@_; $f->{intermediate_signals}{$n}{ast}{operands}[0]{signal} = reference('A')->signal},
        sub {my ($f,$n)=@_; $f->{intermediate_signals}{$n}{ast}{operands}[0]{signal}{name} = 'RENAMED'},
        sub {my ($f,$n)=@_; $f->{_concatenation_width_births}{$n}{record}{extra} = 1},
        sub {my ($f,$n)=@_; $f->{_concatenation_width_births}{$n}{state} = []},
        sub {my ($f,$n)=@_; $f->{_concatenation_width_births}{$n}{extra} = 1},
    ) {
        my ($owner, $allocated) = factor(concat(reference('A'),reference('B')));
        $mutate->($owner,$allocated);
        is(birth($owner,$allocated), undef, 'changed ownership, ordered source, actual reference or schema withholds');
    }
    for my $field (qw(value width radix)) {
        my $literal = FSM::CoreAST::Literal->new('0101', width => 4, radix => 'binary');
        my ($owner,$allocated) = factor(concat(reference('A'),$literal));
        $literal->{$field} = $field eq 'width' ? 5 : $field eq 'radix' ? 'hex' : '101';
        is(birth($owner,$allocated),undef,'raw literal change cannot reuse a numerically similar birth');
    }
    my $unknown = FSM::CoreAST::Literal->new('7');
    my $ast = concat(reference('A'),$unknown);
    my ($owner,$allocated) = factor($ast);
    ok(!defined(FSM::CoreExpressionWidthSupport->infer_width($ast)), 'raw unknown literal gains no exact Core width');
    is($unknown->width,undef,'unknown literal width is not filled by provenance');
    is_deeply([sort keys %{birth($owner,$allocated)}],[qw(expression_tree kind)],'candidate supplies no selected-width or rank policy');
};

subtest 'unsupported and bounded shapes withhold metadata without changing ordinary allocations' => sub {
    ok($has_api, 'bounded birth API exists') or return;
    my $slice = reference('A'); $slice->{slice} = [3,0];
    for my $case (
        [$slice, 1],
        [FSM::CoreAST::IndexedRef->new(reference('A')->signal, FSM::CoreAST::Literal->new('0')), 0],
        [FSM::CoreAST::BinaryOp->new('+',reference('A'),reference('B')), 1],
        [FSM::AST::SignalRef->new('STATE', is_fsm_state_next => 1), 1],
        [FSM::AST::Literal->new("4'b0011"), 1],
    ) {
        my ($operand, $allocates) = @$case;
        my ($owner,$name) = factor(concat(reference('A'),$operand));
        is(defined($name) ? 1 : 0, $allocates, 'ordinary factorizer allocation boundary preserves');
        is(birth($owner,$name),undef,'unsupported operand supplies no sum birth');
        ok(!defined($owner->{intermediate_signals}{$name}{width}),'unknown allocation preserves') if defined $name;
    }
    {
        package Local::ConcatBirthRef;
        our @ISA = ('FSM::CoreAST::SignalRef');
        sub signal { die 'subclass accessor must not run in birth lookup' }
    }
    my ($subclass_owner,$subclass_name) = factor(concat(reference('A'),reference('B')));
    bless $subclass_owner->{intermediate_signals}{$subclass_name}{ast}{operands}[1], 'Local::ConcatBirthRef';
    my ($value,$error);
    eval {$value = $subclass_owner->concatenation_width_birth($subclass_name); 1} or $error=$@;
    is($error,undef,'subclass lookup invokes no foreign getter');
    is($value,undef,'subclassed operand withholds metadata');
    # Mutate only after real bounded allocation: the unrelated factorizer's
    # unbounded rendering/structural walk is outside this lookup contract.
    for my $kind (qw(cycle depth nodes malformed)) {
        my ($owner,$name) = factor(concat(reference('A'),reference('B')));
        my $ast = $owner->{intermediate_signals}{$name}{ast};
        if ($kind eq 'cycle') {$ast->{operands}[1] = $ast}
        elsif ($kind eq 'depth') {my $tree = reference('B'); $tree = concat(reference('A'),$tree) for 1..66; $ast->{operands}[1] = $tree}
        elsif ($kind eq 'nodes') {$ast->{operands} = [(reference('A')) x 4097]}
        else {$ast->{operands} = {bad => 1}}
        is(birth($owner,$name),undef,"$kind lookup withholds within the bounded walk");
        $ast->{operands} = []; # Release the deliberate cycle.
    }
    my ($weak_owner,$weak_ast,$retained);
    {
        my $ast = concat(reference('A'),reference('B'));
        my ($owner,$name) = factor($ast);
        $weak_owner = $owner; $weak_ast = $ast; weaken($weak_owner); weaken($weak_ast);
        $retained = $json->decode($json->encode($owner->{_concatenation_width_births}));
    }
    ok(!defined($weak_owner) && !defined($weak_ast), 'retained capsule owns no factorizer or AST graph');
    ok(defined $retained,'plain capsule remains independently readable');
    my $leaf = reference('A');
    my ($owner,$name) = factor(concat(($leaf) x 4095));
    is(scalar(@{birth($owner,$name)->{expression_tree}}),4096,'exact occurrence bound is admitted without deduplicating slots');
    my $tree = concat(reference('A'),reference('B'));
    $tree = concat(reference('A'),$tree) for 1..63;
    ($owner,$name) = factor($tree);
    ok(defined birth($owner,$name),'exact depth bound remains admitted');
};

subtest 'actual native fixed guards retain birth through both backend generations and reuse' => sub {
    ok($has_api, 'native producer API exists') or return;
    my $source = '(?fsm:concat_birth (+size (A 8) (B 1) (DATA 1) (OTHER 1))'
        ." (idle (<(concat A (concat 4'b0101 B) A) (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $raw = scalar Lispish::multi(\$source);
    my $before = $json->encode($raw);
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm($raw);
    my $backend = FSM::HDL::FlattenedDT->new;
    my $expected = expected(['signal','A'], ['concat',
        ['literal',{value=>'101',width=>4,radix=>'binary'}], ['signal','B']], ['signal','A']);
    for my $language (qw(systemverilog verilog)) {
        my $hdl = $language eq 'verilog' ? $backend->generate_verilog($module) : $backend->generate_systemverilog($module);
        my ($name) = $hdl =~ /^  assign (\w+) = \{A, \{4'b101, B\}, A\}; \/\/ Source: ast_factorization$/m;
        ok(defined $name, 'actual helper assignment preserves full ordered source');
        next unless defined $name;
        like($hdl,qr/^  wire \[20:0\] \Q$name\E;$/m,'actual numeric declaration still has the independent sum');
        is_deeply(birth($backend->{ast_factorizer},$name),$expected,'actual normalized candidate retains original birth');
        is($json->encode($raw),$before,'complete native caller source and JSON kinds preserve');
        is($module->signals->{A}->width,8,'Core source width preserves');
        is($module->signals->{B}->width,1,'Core scalar width preserves');
    }
};
done_testing();
