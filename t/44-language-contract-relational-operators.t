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

subtest 'n-ary relational operators and aliases keep the documented lowering' => sub {
    my $fsm_module = parse_fsm_module(<<'FSM');
(?fsm:relational_operator_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (lt_chain 1)
    (le_chain 1)
    (eq_chain 1)
    (eq_alias 1)
    (ne_chain 1)
    (gt_chain 1)
    (ge_alias 1)
    (not_alias 1)
    (guarded 1)
    (a 8)
    (b 8)
    (c 8)
    (d 8)
    (low 8)
    (mid 8)
    (high 8)
    (flag 1)
  )
  (-ops
    (lt_chain = (< low mid high))
    (le_chain = (<= low mid high))
    (eq_chain = (== a b c d))
    (eq_alias = (eq a b c d))
    (ne_chain = (!= a b c))
    (gt_chain = (> high mid low))
    (ge_alias = (ge high mid low))
    (not_alias = (not flag))
    (guarded = 1 <(<= low mid high))
  )
)
FSM

    my $elements = state_elements($fsm_module, '-ops');
    is(scalar(@$elements), 9, 'relational/operator DT has the expected number of elements');

    my %by_target = map {
        extract_target_name($_) => $_
    } grep {
        $_->isa('FSM::CoreAST::Assignment') || $_->isa('FSM::CoreAST::RegisterAssignment')
    } @$elements;

    assert_relational_chain(
        $by_target{lt_chain}->source,
        '<',
        [
            [qw(low mid)],
            [qw(mid high)],
        ],
        'n-ary < lowering'
    );
    assert_relational_chain(
        $by_target{le_chain}->source,
        '<=',
        [
            [qw(low mid)],
            [qw(mid high)],
        ],
        'n-ary <= lowering'
    );
    assert_relational_chain(
        $by_target{eq_chain}->source,
        '==',
        [
            [qw(a b)],
            [qw(b c)],
            [qw(c d)],
        ],
        'n-ary == lowering'
    );
    assert_relational_chain(
        $by_target{eq_alias}->source,
        '==',
        [
            [qw(a b)],
            [qw(b c)],
            [qw(c d)],
        ],
        'word alias eq lowers to =='
    );
    assert_relational_chain(
        $by_target{ne_chain}->source,
        '!=',
        [
            [qw(a b)],
            [qw(b c)],
        ],
        'n-ary != lowering'
    );
    assert_relational_chain(
        $by_target{gt_chain}->source,
        '>',
        [
            [qw(high mid)],
            [qw(mid low)],
        ],
        'n-ary > lowering'
    );
    assert_relational_chain(
        $by_target{ge_alias}->source,
        '>=',
        [
            [qw(high mid)],
            [qw(mid low)],
        ],
        'word alias ge lowers to >='
    );

    ok($by_target{not_alias}->source->isa('FSM::CoreAST::UnaryOp'), 'word alias not lowers to unary AST');
    is($by_target{not_alias}->source->operator, '!', 'word alias not lowers to !');
    is(expr_leaf_name($by_target{not_alias}->source->operand), 'flag', 'word alias not keeps the same operand');

    my ($guarded_branch) = grep { $_->isa('FSM::CoreAST::ConditionalBranch') } @$elements;
    ok($guarded_branch, 'guarded relational comparison lowers to a ConditionalBranch');
    assert_relational_chain(
        $guarded_branch->condition,
        '<=',
        [
            [qw(low mid)],
            [qw(mid high)],
        ],
        'guarded relational chain lowering'
    );

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/\binput\s+wire\s+\[7:0\]\s+low\b/, 'generated HDL keeps low as a live input');
    like($hdl, qr/\binput\s+wire\s+\[7:0\]\s+mid\b/, 'generated HDL keeps mid as a live input');
    like($hdl, qr/\binput\s+wire\s+\[7:0\]\s+high\b/, 'generated HDL keeps high as a live input');
    like($hdl, qr/\blow\s*<=\s*mid\s*&\s*mid\s*<=\s*high\b/, 'generated HDL preserves chained relational semantics in emitted logic');
    like($hdl, qr/\ba\s*==\s*b\b/, 'generated HDL preserves equality chain comparisons');
    like($hdl, qr/\bhigh\s*>=\s*mid\b/, 'generated HDL preserves alias-based relational comparisons');
};

done_testing();

sub parse_fsm_module {
    my ($fsm_text) = @_;
    my $fsm_path = File::Spec->catfile($tempdir, 'relational_' . int(rand(1_000_000)) . '.fsm');
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

sub assert_relational_chain {
    my ($expr, $comparison_operator, $expected_pairs, $label) = @_;

    my $root = $expr;
    if ($root->isa('FSM::CoreAST::SignalRef') && $root->signal) {
        $root = $root->signal->driving_ast;
    }

    my @comparisons;
    collect_conjunction_terms($root, \@comparisons);
    is(scalar(@comparisons), scalar(@$expected_pairs), "$label keeps the expected number of pairwise comparisons");

    for my $i (0 .. $#comparisons) {
        my $comparison = $comparisons[$i];
        ok($comparison->isa('FSM::CoreAST::BinaryOp'), "$label comparison $i stays as BinaryOp");
        is($comparison->operator, $comparison_operator, "$label comparison $i uses operator '$comparison_operator'");
        is(expr_leaf_name($comparison->left), $expected_pairs->[$i][0], "$label comparison $i keeps left operand");
        is(expr_leaf_name($comparison->right), $expected_pairs->[$i][1], "$label comparison $i keeps right operand");
    }
}

sub collect_conjunction_terms {
    my ($expr, $out) = @_;
    if ($expr->isa('FSM::CoreAST::BinaryOp') && $expr->operator eq '&') {
        collect_conjunction_terms($expr->left, $out);
        collect_conjunction_terms($expr->right, $out);
        return;
    }

    push @$out, $expr;
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

    return ref($expr);
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
