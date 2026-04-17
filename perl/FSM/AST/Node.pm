#!/usr/bin/perl

package FSM::AST::Node;
use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';
use FSM::Package::IntegerLiteralSupport;

=head1 NAME

FSM::AST::Node - Base class for FSM AST nodes

=head1 DESCRIPTION

This module provides the base class and concrete implementations for AST nodes
used throughout the FSM processing pipeline. The entire pipeline works with
AST nodes and only converts to strings at the final RTL generation step.

=cut

# Base AST Node class
sub new ($class, %args) {
    return bless \%args, $class;
}

sub type ($self) {
    return $self->{type};
}

sub to_systemverilog ($self) {
    Carp::confess "to_systemverilog must be implemented by subclasses";
}

sub clone ($self) {
    Carp::confess "clone must be implemented by subclasses";
}

sub equals ($self, $other) {
    Carp::confess "equals must be implemented by subclasses";
}

# Signal Reference Node
package FSM::AST::SignalRef;
use parent 'FSM::AST::Node';

sub new ($class, $signal_name, %args) {
    return $class->SUPER::new(
        type => 'signal_ref',
        signal_name => $signal_name,
        %args
    );
}

sub signal_name ($self) {
    return $self->{signal_name};
}

sub to_systemverilog ($self) {
    return $self->{signal_name};
}

sub clone ($self) {
    return FSM::AST::SignalRef->new($self->{signal_name});
}

sub equals ($self, $other) {
    return ref($other) eq 'FSM::AST::SignalRef' && 
           $self->{signal_name} eq $other->{signal_name};
}

# Literal Value Node  
package FSM::AST::Literal;
use parent 'FSM::AST::Node';

sub new ($class, $value, %args) {
    return $class->SUPER::new(
        type => 'literal',
        value => $value,
        %args
    );
}

sub value ($self) {
    return $self->{value};
}

sub to_systemverilog ($self) {
    my $value = $self->{value};
    
    # Convert common literal values to SystemVerilog format
    if ($value eq '0') {
        return "1'b0";
    } elsif ($value eq '1') {
        return "1'b1";
    } elsif (defined(my $normalized = FSM::Package::IntegerLiteralSupport->systemverilog_literal_from_literal_like($self))) {
        return $normalized;
    } elsif ($value =~ /^\d+$/) {
        return $value;
    } else {
        return $value;
    }
}

sub clone ($self) {
    return FSM::AST::Literal->new($self->{value});
}

sub equals ($self, $other) {
    return ref($other) eq 'FSM::AST::Literal' && 
           $self->{value} eq $other->{value};
}

# Unary Operation Node
package FSM::AST::UnaryOp;
use parent 'FSM::AST::Node';

sub new ($class, $operator, $operand, %args) {
    return $class->SUPER::new(
        type => 'unary_op',
        operator => $operator,
        operand => $operand,
        %args
    );
}

sub operator ($self) {
    return $self->{operator};
}

sub operand ($self) {
    return $self->{operand};
}

sub to_systemverilog ($self) {
    my $op = $self->{operator};
    my $operand_sv = $self->{operand}->to_systemverilog();
    
    if ($op eq '!') {
        return "!$operand_sv";
    } else {
        return "$op$operand_sv";
    }
}

sub clone ($self) {
    return FSM::AST::UnaryOp->new(
        $self->{operator},
        $self->{operand}->clone()
    );
}

sub equals ($self, $other) {
    return ref($other) eq 'FSM::AST::UnaryOp' && 
           $self->{operator} eq $other->{operator} &&
           $self->{operand}->equals($other->{operand});
}

# Binary Operation Node
package FSM::AST::BinaryOp;
use parent 'FSM::AST::Node';

sub new ($class, $operator, $left, $right, %args) {
    return $class->SUPER::new(
        type => 'binary_op',
        operator => $operator,
        left => $left,
        right => $right,
        %args
    );
}

sub operator ($self) {
    return $self->{operator};
}

sub left ($self) {
    return $self->{left};
}

sub right ($self) {
    return $self->{right};
}

sub to_systemverilog ($self) {
    my $op = $self->{operator};
    my $left_sv = $self->{left}->to_systemverilog();
    my $right_sv = $self->{right}->to_systemverilog();
    
    # Handle different operator types with appropriate parentheses
    if ($op eq '&&' || $op eq '||') {
        return "($left_sv $op $right_sv)";
    } elsif ($op eq '&' || $op eq '|') {
        return "$left_sv $op $right_sv";
    } elsif ($op eq '==' || $op eq '!=' || $op eq '<' || $op eq '>' || $op eq '<=' || $op eq '>=') {
        return "$left_sv $op $right_sv";
    } else {
        return "($left_sv $op $right_sv)";
    }
}

sub clone ($self) {
    return FSM::AST::BinaryOp->new(
        $self->{operator},
        $self->{left}->clone(),
        $self->{right}->clone()
    );
}

sub equals ($self, $other) {
    return ref($other) eq 'FSM::AST::BinaryOp' && 
           $self->{operator} eq $other->{operator} &&
           $self->{left}->equals($other->{left}) &&
           $self->{right}->equals($other->{right});
}

# Logical Constant Node (for true/false)
package FSM::AST::LogicalConstant;
use parent 'FSM::AST::Node';

sub new ($class, $value, %args) {
    return $class->SUPER::new(
        type => 'logical_constant',
        value => $value ? 1 : 0,
        %args
    );
}

sub value ($self) {
    return $self->{value};
}

sub is_true ($self) {
    return $self->{value};
}

sub is_false ($self) {
    return !$self->{value};
}

sub to_systemverilog ($self) {
    return $self->{value} ? "1'b1" : "1'b0";
}

sub clone ($self) {
    return FSM::AST::LogicalConstant->new($self->{value});
}

sub equals ($self, $other) {
    return ref($other) eq 'FSM::AST::LogicalConstant' && 
           $self->{value} == $other->{value};
}

# AST Utility Functions
package FSM::AST::Utils;

# Create common AST nodes with convenience functions
sub signal_ref ($signal_name) {
    return FSM::AST::SignalRef->new($signal_name);
}

sub literal ($value) {
    return FSM::AST::Literal->new($value);
}

sub logical_true () {
    return FSM::AST::LogicalConstant->new(1);
}

sub logical_false () {
    return FSM::AST::LogicalConstant->new(0);
}

sub not_op ($operand) {
    return FSM::AST::UnaryOp->new('!', $operand);
}

sub and_op ($left, $right) {
    return FSM::AST::BinaryOp->new('&&', $left, $right);
}

sub or_op ($left, $right) {
    return FSM::AST::BinaryOp->new('||', $left, $right);
}

sub bitwise_and ($left, $right) {
    return FSM::AST::BinaryOp->new('&', $left, $right);
}

sub equals_op ($left, $right) {
    return FSM::AST::BinaryOp->new('==', $left, $right);
}

# Build AND tree from multiple operands
sub and_tree (@operands) {
    return logical_true() unless @operands;
    return $operands[0] if @operands == 1;
    
    my $result = $operands[0];
    for my $i (1 .. $#operands) {
        $result = and_op($result, $operands[$i]);
    }
    return $result;
}

# Build OR tree from multiple operands  
sub or_tree (@operands) {
    return logical_false() unless @operands;
    return $operands[0] if @operands == 1;
    
    my $result = $operands[0];
    for my $i (1 .. $#operands) {
        $result = or_op($result, $operands[$i]);
    }
    return $result;
}

1;
