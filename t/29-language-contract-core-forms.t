#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw/ tempdir /;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'guarded blocks and suffix guards are regression-backed' => sub {
    my $fsm_module = parse_fsm_module(<<'FSM');
(?fsm:guard_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 8)
    (B 8)
    (C 8)
    (D 8)
    (req 1)
    (full 1)
    (start 1)
  )
  (idle
    (<req
      (A <= B)
      (<!full
        (C = A)
        (-> busy)
      )
    )
    (<(& req start !full)
      (D = C)
    )
    (A <= C <start)
    (-> busy <!full)
  )
  (busy
    (A <= B)
  )
)
FSM

    my $idle_elements = state_elements($fsm_module, 'idle');
    is(scalar(@$idle_elements), 4, 'idle state has the expected top-level guarded/suffixed elements');

    my $outer_guard = $idle_elements->[0];
    ok($outer_guard->isa('FSM::CoreAST::ConditionalBranch'), 'simple guarded block parses as ConditionalBranch');
    ok($outer_guard->condition->isa('FSM::CoreAST::BinaryOp'), 'simple <req guard lowers to explicit comparison AST');
    is($outer_guard->condition->operator, '!=', 'simple <req guard uses != comparison');
    is($outer_guard->condition->left->signal->name, 'req', 'simple <req guard compares req on the left');
    is($outer_guard->condition->right->to_systemverilog, '0', 'simple <req guard compares against zero');

    my $outer_actions = $outer_guard->branches->[0]{actions};
    is(scalar(@$outer_actions), 2, 'outer guarded block keeps both nested actions');
    ok($outer_actions->[0]->isa('FSM::CoreAST::RegisterAssignment'), 'outer guarded block keeps the nested assignment');

    my $inner_guard = $outer_actions->[1];
    ok($inner_guard->isa('FSM::CoreAST::ConditionalBranch'), 'nested <!full block stays nested as ConditionalBranch');
    ok($inner_guard->condition->isa('FSM::CoreAST::BinaryOp'), 'nested <!full guard lowers to explicit comparison AST');
    is($inner_guard->condition->operator, '==', 'nested <!full guard uses == comparison');
    is($inner_guard->condition->left->signal->name, 'full', 'nested <!full guard compares full on the left');
    is($inner_guard->condition->right->to_systemverilog, '0', 'nested <!full guard compares against zero');
    my $inner_actions = $inner_guard->branches->[0]{actions};
    is(scalar(@$inner_actions), 2, 'nested guarded block keeps both nested actions');
    ok($inner_actions->[0]->isa('FSM::CoreAST::Assignment'), 'nested guarded block keeps combinational assignment');
    ok($inner_actions->[1]->isa('FSM::CoreAST::StateTransition'), 'nested guarded block keeps state transition');
    is($inner_actions->[1]->target_state, 'busy', 'nested guarded transition preserves target state');

    my $logical_guard = $idle_elements->[1];
    ok($logical_guard->isa('FSM::CoreAST::ConditionalBranch'), 'general logical guarded block parses as ConditionalBranch');
    ok($logical_guard->condition->isa('FSM::CoreAST::SignalRef'), 'logical guarded block lowers through an intermediate signal');
    my $logical_ast = $logical_guard->condition->signal->driving_ast;
    ok($logical_ast && $logical_ast->isa('FSM::CoreAST::BinaryOp'), 'logical guarded block keeps a driving AST on the intermediate');
    assert_left_associative_binary_tree(
        $logical_ast,
        '&',
        ['req', 'start', '!full'],
        'logical guarded block condition tree'
    );

    my $assignment_suffix = $idle_elements->[2];
    ok($assignment_suffix->isa('FSM::CoreAST::ConditionalBranch'), 'assignment suffix guard lowers to ConditionalBranch');
    ok($assignment_suffix->branches->[0]{actions}[0]->isa('FSM::CoreAST::RegisterAssignment'), 'assignment suffix guard keeps assignment action');
    is($assignment_suffix->condition->operator, '!=', 'assignment suffix guard uses != comparison');
    is($assignment_suffix->condition->left->signal->name, 'start', 'assignment suffix guard compares start on the left');
    is($assignment_suffix->condition->right->to_systemverilog, '0', 'assignment suffix guard compares against zero');

    my $transition_suffix = $idle_elements->[3];
    ok($transition_suffix->isa('FSM::CoreAST::ConditionalBranch'), 'transition suffix guard lowers to ConditionalBranch');
    ok($transition_suffix->branches->[0]{actions}[0]->isa('FSM::CoreAST::StateTransition'), 'transition suffix guard keeps transition action');
    is($transition_suffix->condition->operator, '==', 'transition suffix guard uses == comparison');
    is($transition_suffix->condition->left->signal->name, 'full', 'transition suffix guard compares full on the left');
    is($transition_suffix->condition->right->to_systemverilog, '0', 'transition suffix guard compares against zero');

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/module\s+guard_contract\b/s, 'guard-contract FSM still generates HDL through the active backend');
};

subtest 'compound updates normalize to explicit assignment intent and arithmetic ASTs' => sub {
    my $fsm_module = parse_fsm_module(<<'FSM');
(?fsm:update_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (counter 8)
    (retry_count 8)
    (byte_count 8)
    (remaining 8)
    (SRC 8)
    (ACC 8)
    (COMB 8)
  )
  (-updates
    (++ counter)
    (-- retry_count)
    (+=4 byte_count)
    (-=1 remaining)
    (ACC <- SRC (+= 2))
    (COMB = SRC (-= 1))
  )
)
FSM

    my $elements = state_elements($fsm_module, '-updates');
    is(scalar(@$elements), 6, 'standalone update DT has the expected number of actions');

    my %assignment_by_target = map {
        extract_target_name($_) => $_
    } grep {
        $_->isa('FSM::CoreAST::Assignment') || $_->isa('FSM::CoreAST::RegisterAssignment')
    } @$elements;

    is($assignment_by_target{counter}->operator_symbol, '<-', '++ shorthand normalizes to register-style assignment');
    is($assignment_by_target{counter}->source_provenance->{compound_operator}, '+=', '++ shorthand records += provenance');
    is($assignment_by_target{counter}->source_provenance->{compound_delta}, '1', '++ shorthand records delta 1');
    assert_left_associative_binary_tree(
        $assignment_by_target{counter}->source,
        '+',
        [qw(counter 1)],
        '++ shorthand arithmetic tree'
    );

    is($assignment_by_target{retry_count}->source_provenance->{compound_operator}, '-=', '-- shorthand records -= provenance');
    is($assignment_by_target{retry_count}->source_provenance->{compound_delta}, '1', '-- shorthand records delta 1');
    assert_left_associative_binary_tree(
        $assignment_by_target{retry_count}->source,
        '-',
        [qw(retry_count 1)],
        '-- shorthand arithmetic tree'
    );

    is($assignment_by_target{byte_count}->source_provenance->{compound_operator}, '+=', '+=N shorthand records += provenance');
    is($assignment_by_target{byte_count}->source_provenance->{compound_delta}, '4', '+=N shorthand records explicit delta');
    assert_left_associative_binary_tree(
        $assignment_by_target{byte_count}->source,
        '+',
        [qw(byte_count 4)],
        '+=N shorthand arithmetic tree'
    );

    is($assignment_by_target{remaining}->source_provenance->{compound_operator}, '-=', '-=N shorthand records -= provenance');
    is($assignment_by_target{remaining}->source_provenance->{compound_delta}, '1', '-=N shorthand records explicit delta');
    assert_left_associative_binary_tree(
        $assignment_by_target{remaining}->source,
        '-',
        [qw(remaining 1)],
        '-=N shorthand arithmetic tree'
    );

    is($assignment_by_target{ACC}->operator_symbol, '<-', 'inline (+= N) modifier keeps the surrounding register assignment family');
    is($assignment_by_target{ACC}->source_provenance->{compound_operator}, '+=', 'inline (+= N) modifier records += provenance');
    is($assignment_by_target{ACC}->source_provenance->{compound_delta}, '2', 'inline (+= N) modifier records explicit delta');
    assert_left_associative_binary_tree(
        $assignment_by_target{ACC}->source,
        '+',
        [qw(SRC 2)],
        'inline (+= N) modifier arithmetic tree'
    );

    is($assignment_by_target{COMB}->operator_symbol, '=', 'inline (-= N) modifier keeps the surrounding combinational assignment family');
    is($assignment_by_target{COMB}->source_provenance->{compound_operator}, '-=', 'inline (-= N) modifier records -= provenance');
    is($assignment_by_target{COMB}->source_provenance->{compound_delta}, '1', 'inline (-= N) modifier records explicit delta');
    assert_left_associative_binary_tree(
        $assignment_by_target{COMB}->source,
        '-',
        [qw(SRC 1)],
        'inline (-= N) modifier arithmetic tree'
    );

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/module\s+update_contract\b/s, 'update-contract FSM still generates HDL through the active backend');
};

subtest 'broader operator expressions keep their documented lowering' => sub {
    my $fsm_module = parse_fsm_module(<<'FSM');
(?fsm:operator_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (sum 8)
    (diff 8)
    (prod 8)
    (quo 8)
    (rem 8)
    (alias_sum 8)
    (mask 1)
    (alias_xor 1)
    (a 8)
    (b 8)
    (c 8)
    (d 8)
    (x 1)
    (y 1)
    (z 1)
  )
  (-math
    (sum = (+ a b c d))
    (diff = (- a b c d))
    (prod = (* a b c d))
    (quo = (/ a b c d))
    (rem = (% a b c d))
    (alias_sum = (add a b c d))
    (mask = (^ x y z))
    (alias_xor = (xor x y z))
  )
)
FSM

    my $elements = state_elements($fsm_module, '-math');
    is(scalar(@$elements), 8, 'math DT has the expected number of assignments');

    my %assignment_by_target = map {
        extract_target_name($_) => $_
    } grep {
        $_->isa('FSM::CoreAST::Assignment') || $_->isa('FSM::CoreAST::RegisterAssignment')
    } @$elements;

    assert_left_associative_binary_tree(
        $assignment_by_target{sum}->source,
        '+',
        [qw(a b c d)],
        'n-ary + lowering'
    );
    assert_left_associative_binary_tree(
        $assignment_by_target{diff}->source,
        '-',
        [qw(a b c d)],
        'n-ary - lowering'
    );
    assert_left_associative_binary_tree(
        $assignment_by_target{prod}->source,
        '*',
        [qw(a b c d)],
        'n-ary * lowering'
    );
    assert_left_associative_binary_tree(
        $assignment_by_target{quo}->source,
        '/',
        [qw(a b c d)],
        'n-ary / lowering'
    );
    assert_left_associative_binary_tree(
        $assignment_by_target{rem}->source,
        '%',
        [qw(a b c d)],
        'n-ary % lowering'
    );
    assert_left_associative_binary_tree(
        $assignment_by_target{alias_sum}->source,
        '+',
        [qw(a b c d)],
        'word alias add lowers to +'
    );

    ok($assignment_by_target{mask}->source->isa('FSM::CoreAST::SignalRef'), 'n-ary ^ lowering uses an intermediate signal in the active parser');
    ok($assignment_by_target{alias_xor}->source->isa('FSM::CoreAST::SignalRef'), 'word alias xor also uses an intermediate signal');
    assert_left_associative_binary_tree(
        $assignment_by_target{mask}->source->signal->driving_ast,
        '^',
        [qw(x y z)],
        'n-ary ^ intermediate keeps the XOR driving AST'
    );
    assert_left_associative_binary_tree(
        $assignment_by_target{alias_xor}->source->signal->driving_ast,
        '^',
        [qw(x y z)],
        'word alias xor lowers to the same XOR driving AST'
    );

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/module\s+operator_contract\b/s, 'operator-contract FSM still generates HDL through the active backend');
};

done_testing();

sub parse_fsm_module {
    my ($fsm_text) = @_;
    my $fsm_path = File::Spec->catfile($tempdir, "contract_" . int(rand(1_000_000)) . ".fsm");
    write_file($fsm_path, $fsm_text);

    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    return $adapter->parse_fsm($raw_ast);
}

sub state_elements {
    my ($fsm_module, $state_name) = @_;
    my ($state) = grep { $_->name eq $state_name } @{ $fsm_module->states || [] };
    ok($state, "found state '$state_name'");
    return [] unless $state;

    my @elements;
    for my $dt (@{ $state->decision_trees || [] }) {
        push @elements, @{ $dt->elements || [] };
    }
    return \@elements;
}

sub extract_target_name {
    my ($assignment) = @_;
    return undef unless $assignment && $assignment->can('target');
    my $target = $assignment->target;
    return undef unless $target;

    if ($target->can('name')) {
        my $name = eval { $target->name };
        return $name if defined $name;
    }

    if ($target->can('signal') && $target->signal && $target->signal->can('name')) {
        return $target->signal->name;
    }

    return undef;
}

sub assert_left_associative_binary_tree {
    my ($expr, $operator, $expected_leaves, $label) = @_;
    my @expected = @$expected_leaves;
    my $node = $expr;

    for (my $i = $#expected; $i >= 1; $i--) {
        ok($node->isa('FSM::CoreAST::BinaryOp'), "$label keeps BinaryOp node for position $i");
        is($node->operator, $operator, "$label uses operator '$operator' at position $i");
        is(expr_leaf_name($node->right), $expected[$i], "$label keeps right operand $expected[$i] at position $i");

        if ($i == 1) {
            is(expr_leaf_name($node->left), $expected[0], "$label keeps leftmost operand $expected[0]");
        } else {
            $node = $node->left;
        }
    }
}

sub expr_leaf_name {
    my ($expr) = @_;
    return undef unless $expr;

    if ($expr->isa('FSM::CoreAST::SignalRef') && $expr->signal) {
        return $expr->signal->name;
    }

    if ($expr->isa('FSM::CoreAST::Literal')) {
        return $expr->value;
    }

    if ($expr->isa('FSM::CoreAST::UnaryOp') &&
        $expr->operator eq '!' &&
        $expr->operand &&
        $expr->operand->isa('FSM::CoreAST::SignalRef') &&
        $expr->operand->signal) {
        return '!' . $expr->operand->signal->name;
    }

    return ref($expr);
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
