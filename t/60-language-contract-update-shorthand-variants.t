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

subtest 'alternate update-shorthand spellings keep the same assignment intent' => sub {
    my $fsm_module = parse_fsm_module(<<'FSM');
(?fsm:update_variant_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (counter 8)
    (retry_count 8)
    (byte_count 8)
    (remaining 8)
  )
  (-updates
    (+= counter)
    (-= retry_count)
    (+= byte_count 4)
    (-= remaining 3)
  )
)
FSM

    my $elements = state_elements($fsm_module, '-updates');
    is(scalar(@$elements), 4, 'standalone update DT has the expected number of alternate shorthand actions');

    my %assignment_by_target = map {
        extract_target_name($_) => $_
    } grep {
        $_->isa('FSM::CoreAST::Assignment') || $_->isa('FSM::CoreAST::RegisterAssignment')
    } @$elements;

    is($assignment_by_target{counter}->operator_symbol, '<-', '(+= sig) keeps register-style assignment family');
    is($assignment_by_target{counter}->source_provenance->{compound_operator}, '+=', '(+= sig) records += provenance');
    is($assignment_by_target{counter}->source_provenance->{compound_delta}, '1', '(+= sig) defaults delta to 1');
    assert_left_associative_binary_tree(
        $assignment_by_target{counter}->source,
        '+',
        [qw(counter 1)],
        '(+= sig) arithmetic tree'
    );

    is($assignment_by_target{retry_count}->operator_symbol, '<-', '(-= sig) keeps register-style assignment family');
    is($assignment_by_target{retry_count}->source_provenance->{compound_operator}, '-=', '(-= sig) records -= provenance');
    is($assignment_by_target{retry_count}->source_provenance->{compound_delta}, '1', '(-= sig) defaults delta to 1');
    assert_left_associative_binary_tree(
        $assignment_by_target{retry_count}->source,
        '-',
        [qw(retry_count 1)],
        '(-= sig) arithmetic tree'
    );

    is($assignment_by_target{byte_count}->operator_symbol, '<-', '(+= sig N) keeps register-style assignment family');
    is($assignment_by_target{byte_count}->source_provenance->{compound_operator}, '+=', '(+= sig N) records += provenance');
    is($assignment_by_target{byte_count}->source_provenance->{compound_delta}, '4', '(+= sig N) records explicit delta');
    assert_left_associative_binary_tree(
        $assignment_by_target{byte_count}->source,
        '+',
        [qw(byte_count 4)],
        '(+= sig N) arithmetic tree'
    );

    is($assignment_by_target{remaining}->operator_symbol, '<-', '(-= sig N) keeps register-style assignment family');
    is($assignment_by_target{remaining}->source_provenance->{compound_operator}, '-=', '(-= sig N) records -= provenance');
    is($assignment_by_target{remaining}->source_provenance->{compound_delta}, '3', '(-= sig N) records explicit delta');
    assert_left_associative_binary_tree(
        $assignment_by_target{remaining}->source,
        '-',
        [qw(remaining 3)],
        '(-= sig N) arithmetic tree'
    );

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/module\s+update_variant_contract\b/s, 'alternate update shorthand still generates HDL through the active backend');
};

done_testing();

sub parse_fsm_module {
    my ($fsm_text) = @_;
    my $fsm_path = File::Spec->catfile($tempdir, 'update_variant_' . int(rand(1_000_000)) . '.fsm');
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

    return ref($expr);
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
