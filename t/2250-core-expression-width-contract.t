use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::CoreAST;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;

my $available = eval {require FSM::CoreExpressionWidthSupport; 1};
ok($available, 'canonical Core expression width contract is available') or diag $@;
unless ($available) {done_testing(); exit}
my $class = 'FSM::CoreExpressionWidthSupport';
my $json = JSON::PP->new->canonical;
sub width { $class->infer_width(@_) }
sub literal { FSM::CoreAST::Literal->new(@_) }
sub binary { FSM::CoreAST::BinaryOp->new(@_) }
sub reference { FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name => $_[0], width => $_[1])) }
sub unary { FSM::CoreAST::UnaryOp->new(operator => $_[0], operand => $_[1]) }

subtest 'unsized literals have no Core default and only the explicit resolver supplies a target width' => sub {
    my $unsized = literal('3');
    my $expr = binary('&', reference('A', 8), $unsized);
    ok(!defined(width($expr)), 'unsized width remains unknown in target-neutral Core');
    my @seen;
    is(width($expr, unsized_literal_width => sub {push @seen, $_[0]; 32}), 32,
        'an explicit target-owned literal floor participates in the same max walk');
    is_deeply(\@seen, [{value => '3', radix => 'decimal', width => undef}], 'resolver receives raw detached literal data');
    is(width(binary('|', reference('WIDE', 64), $unsized), unsized_literal_width => sub {32}), 64,
        'a separately wider signal wins without resizing the literal');
    for my $bad (undef, 0, -1, 'unknown', {}, JSON::PP::true) {
        ok(!defined(width($expr, unsized_literal_width => sub {$bad})), 'invalid target width stays unknown');
    }
    my $future = FSM::CoreAST::Expression->new(type => 'future_width_shape');
    my $calls = 0;
    ok(!defined(width(binary('&', reference('A', 8), $future),
        unsized_literal_width => sub {++$calls; 32})), 'unknown future shape cannot borrow literal sizing');
    is($calls, 0, 'resolver sees only actual unsized literals');
    eval {width($expr, unsized_literal_width => sub {die "target refusal\n"})};
    like($@, qr/target refusal/, 'target resolver failures propagate');
    eval {width($expr, unsized_literal_width => 32)};
    like($@, qr/callback/, 'an invalid resolver contract refuses');
};

subtest 'explicit literal floors and raw value radix and JSON kinds conserve' => sub {
    for my $case (['10000000', 8, 'binary'], ['F', 4, 'hex'], [3, 3, 'decimal'], ['7', 3, 'octal']) {
        my ($value, $bits, $radix) = @$case;
        my $lit = literal($value, width => $bits, radix => $radix);
        my $before = $json->encode([$lit->value, $lit->width, $lit->radix]);
        my $calls = 0;
        is(width(binary('|', reference('BIT', 1), $lit), unsized_literal_width => sub {++$calls; 32}), $bits,
            'explicit literal width is an independent constraint');
        is($calls, 0, 'target policy cannot replace an explicitly sized literal');
        is($json->encode([$lit->value, $lit->width, $lit->radix]), $before, 'source literal kinds and data preserve');
    }
    for my $value (3, '3') {
        my $lit = literal($value, radix => 'hex');
        my $before = $json->encode([$lit->value, $lit->width, $lit->radix]);
        my $seen;
        is(width($lit, unsized_literal_width => sub {
            $seen = $json->encode($_[0]); $_[0]{value} = 'changed'; $_[0]{radix} = 'binary'; return 32;
        }), 32, 'unsized resolver gets its own record');
        is($seen, $json->encode({value => $value, width => undef, radix => 'hex'}), 'callback preserves raw numeric versus string kind');
        is($json->encode([$lit->value, $lit->width, $lit->radix]), $before, 'callback mutation cannot change Core');
    }
    ok(!defined(width(literal('3', width => 0), unsized_literal_width => sub {32})),
        'invalid explicit size cannot masquerade as unsized');
};

subtest 'scalar wrappers known composites cycles and shared occurrences have precise boundaries' => sub {
    my $unknown = literal('3');
    my $calls = 0;
    for my $expr (unary('!', $unknown), unary('&', reference('A', 8)), binary('==', reference('A', 8), $unknown)) {
        is(width($expr, unsized_literal_width => sub {++$calls; 32}), 1, 'scalar result does not inherit operand width');
    }
    is($calls, 0, 'scalar width does not need target literal inference');
    is(width(unary('~', reference('A', 8))), 8, 'ordinary unary result preserves operand width');
    is(width(FSM::CoreAST::Concatenation->new(reference('A', 8), literal('1', width => 3))), 11,
        'known concatenation retains the independent sum');
    my $leaf = reference('A', 1);
    my $deep = $leaf;
    $deep = binary('&', $deep, $leaf) for 1 .. $class->MAX_DEPTH;
    is(width($deep), 1, 'declared depth boundary is inclusive');
    ok(!defined(width(binary('&', $deep, $leaf))), 'next depth refuses boundedly');
    my $cycle = binary('&', $leaf, $leaf); $cycle->{operands}[0] = $cycle;
    ok(!defined(width($cycle)), 'active AST cycle stays unknown');
    $cycle->{operands}[0] = $leaf;
    is(width($cycle), 1, 'failed walk does not poison a later call');
    my $shared = $leaf;
    $shared = binary('|', $shared, $shared) for 1 .. 11;
    is(width($shared), 1, 'shared subtrees retain all admitted visited occurrences');
    ok(!defined(width(binary('|', $shared, $shared))), 'over-budget repeated occurrences refuse');
};

subtest 'actual source allocation and caller products conserve through final target agreement' => sub {
    for my $bits (1, 8) {for my $mutable (0, 1) {
        my $params = $mutable ? "(+params (W $bits))" : '';
        my $slot = $mutable ? '(param W)' : $bits;
        my $source = "(?fsm:literal_width $params (+size (A $slot) (B $slot) (DATA 1) (OTHER 1))"
            .' (idle (<(& A B 3) (= (DATA 1)) (= (OTHER 1))) (-> idle)))';
        my $adapter = FSM::Adapter::FSMGenFull->new;
        my $module = $adapter->parse_fsm(scalar Lispish::multi(\$source));
        my ($helper) = grep {$_->get_attribute('is_intermediate') && $_->driving_ast} values %{$module->signals};
        ok($helper, 'actual parser owns the unresolved helper');
        my $before = $json->encode([$module->parameters, $module->parameter_default_sources, $module->parameter_default_bindings,
            {map {my $s = $module->signals->{$_}; $_ => [$s->width, $s->declared_width_binding,
                $s->declared_width_requirements, $s->driving_ast ? $s->driving_ast->to_systemverilog : undef]} keys %{$module->signals}}]);
        is($helper->width, 1, 'ordinary unresolved compatibility placeholder remains unchanged');
        ok(!defined($adapter->{expression_builder}->infer_exact_expression_width($helper->driving_ast)),
            'ordinary builder still reports unknown exact source width');
        is(width($helper->driving_ast, unsized_literal_width => sub {32}), 32, 'same actual source can be sized by explicit target policy');
        my $hdl = eval {FSM::HDL::FlattenedDT->new->generate_systemverilog($module)};
        is($@, '', 'actual fixed or mutable source completes final target agreement');
        ok(defined($hdl), 'generation returns the complete HDL');
        my $name = $helper->name;
        if ($mutable) {
            like($hdl // '', qr/^  wire \[[^\n]*\bW\b[^\n]*\b32\b[^\n]*:0\] \Q$name\E;$/m,
                'mutable target retains the original parameter and unsized literal floor');
        } else {
            like($hdl // '', qr/^  wire \[31:0\] \Q$name\E;$/m,
                'fixed target sizes its unsized literal while the Core placeholder remains unresolved');
        }
        my $after = $json->encode([$module->parameters, $module->parameter_default_sources, $module->parameter_default_bindings,
            {map {my $s = $module->signals->{$_}; $_ => [$s->width, $s->declared_width_binding,
                $s->declared_width_requirements, $s->driving_ast ? $s->driving_ast->to_systemverilog : undef]} keys %{$module->signals}}]);
        is($after, $before, 'actual source declarations literal expressions parameter provenance and JSON kinds conserve');
    }}
};
done_testing();
