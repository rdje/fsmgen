#!/usr/bin/perl

package FSM::AST::Utils;
use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);

use Scalar::Util qw(blessed);
use FSM::AST::Node;

=head1 NAME

FSM::AST::Utils - Utility functions for creating and manipulating AST nodes

=head1 DESCRIPTION

This module provides utility functions for creating and manipulating AST nodes
in a pure AST-based approach. It replaces string manipulation with proper AST 
node construction and manipulation.

=head1 SYNOPSIS

  use FSM::AST::Utils;
  
  # Create signal reference
  my $signal = FSM::AST::Utils::signal_ref('apb_rq');
  
  # Create literal
  my $literal = FSM::AST::Utils::literal("1'b1");
  
  # Create binary operations
  my $and_node = FSM::AST::Utils::and_op($signal, $literal);
  my $or_node = FSM::AST::Utils::or_op($node1, $node2);
  
  # Create trees of operations
  my $and_tree = FSM::AST::Utils::and_tree($node1, $node2, $node3);

=cut

=head2 signal_ref

Create a signal reference AST node.

=cut

sub signal_ref ($signal_name, %args) {
    return FSM::AST::SignalRef->new($signal_name, %args);
}

=head2 literal

Create a literal AST node.

=cut

sub literal ($value) {
    return FSM::AST::Node::Literal->new($value);
}

=head2 and_op

Create a binary AND operation AST node.

=cut

sub and_op ($left, $right) {
    return FSM::AST::Node::BinaryOp->new($left, '&', $right);
}

=head2 or_op  

Create a binary OR operation AST node.

=cut

sub or_op ($left, $right) {
    return FSM::AST::Node::BinaryOp->new($left, '|', $right);
}

=head2 not_op

Create a unary NOT operation AST node.

=cut

sub not_op ($operand) {
    return FSM::AST::Node::UnaryOp->new('!', $operand);
}

=head2 equals_op

Create a binary equality comparison AST node.

=cut

sub equals_op ($left, $right) {
    return FSM::AST::Node::BinaryOp->new($left, '==', $right);
}

=head2 and_tree

Create an AND tree from multiple nodes. For a single node, returns the node itself.
For multiple nodes, creates a balanced AND tree.

=cut

sub and_tree (@nodes) {
    return literal("1'b1") if @nodes == 0;
    return $nodes[0] if @nodes == 1;
    
    # Create balanced AND tree for multiple nodes
    return _create_balanced_tree(\&and_op, @nodes);
}

=head2 or_tree

Create an OR tree from multiple nodes. For a single node, returns the node itself.
For multiple nodes, creates a balanced OR tree.

=cut

sub or_tree (@nodes) {
    return literal("1'b0") if @nodes == 0;
    return $nodes[0] if @nodes == 1;
    
    # Create balanced OR tree for multiple nodes
    return _create_balanced_tree(\&or_op, @nodes);
}

=head2 _create_balanced_tree

Internal helper to create balanced binary trees.

=cut

sub _create_balanced_tree ($op_func, @nodes) {
    return $nodes[0] if @nodes == 1;
    
    # For two nodes, apply operation directly
    if (@nodes == 2) {
        return $op_func->($nodes[0], $nodes[1]);
    }
    
    # For more nodes, split in half and recurse
    my $mid = int(@nodes / 2);
    my @left_nodes = @nodes[0..$mid-1];
    my @right_nodes = @nodes[$mid..$#nodes];
    
    my $left_tree = _create_balanced_tree($op_func, @left_nodes);
    my $right_tree = _create_balanced_tree($op_func, @right_nodes);
    
    return $op_func->($left_tree, $right_tree);
}

=head2 is_ast_node

Check if a value is a proper AST node.

=cut

sub is_ast_node ($value) {
    return 0 unless defined $value;
    return 0 unless ref($value) && blessed($value);
    return $value->isa('FSM::AST::Node');
}

=head2 clone_ast_node

Create a deep clone of an AST node.

=cut

sub clone_ast_node ($node) {
    return undef unless defined $node;
    return $node unless is_ast_node($node);
    
    if ($node->isa('FSM::AST::Node::SignalRef')) {
        return signal_ref($node->name);
    } elsif ($node->isa('FSM::AST::Node::Literal')) {
        return literal($node->value);
    } elsif ($node->isa('FSM::AST::Node::BinaryOp')) {
        my $left_clone = clone_ast_node($node->left);
        my $right_clone = clone_ast_node($node->right);
        return FSM::AST::Node::BinaryOp->new($left_clone, $node->operator, $right_clone);
    } elsif ($node->isa('FSM::AST::Node::UnaryOp')) {
        my $operand_clone = clone_ast_node($node->operand);
        return FSM::AST::Node::UnaryOp->new($node->operator, $operand_clone);
    } else {
        # For unknown node types, return as-is
        return $node;
    }
}

=head2 ast_to_debug_string

Convert an AST node to a debug string representation.

=cut

sub ast_to_debug_string ($node, $indent = 0) {
    return "(undef)" unless defined $node;
    
    my $prefix = "  " x $indent;
    
    unless (is_ast_node($node)) {
        return "$prefix(non-AST: " . (ref($node) || "SCALAR") . ")";
    }
    
    if ($node->isa('FSM::AST::Node::SignalRef')) {
        return "$prefix SignalRef: " . $node->name;
    } elsif ($node->isa('FSM::AST::Node::Literal')) {
        return "$prefix Literal: " . $node->value;
    } elsif ($node->isa('FSM::AST::Node::BinaryOp')) {
        my $result = "$prefix BinaryOp: " . $node->operator . "\n";
        $result .= ast_to_debug_string($node->left, $indent + 1) . "\n";
        $result .= ast_to_debug_string($node->right, $indent + 1);
        return $result;
    } elsif ($node->isa('FSM::AST::Node::UnaryOp')) {
        my $result = "$prefix UnaryOp: " . $node->operator . "\n";
        $result .= ast_to_debug_string($node->operand, $indent + 1);
        return $result;
    } else {
        return "$prefix Unknown AST node: " . ref($node);
    }
}

1;

__END__

=head1 AUTHOR

Generated for FSM AST processing system

=head1 COPYRIGHT

Copyright (c) 2024. All rights reserved.

=cut
