package FSM::ASTv2;

# Modern FSM AST with S-expression Condition Support
# Perl 5.20+ features and S-expression based decision trees

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef switch);
no warnings qw(experimental::signatures experimental::postderef experimental::smartmatch);

#==============================================================================
# Condition AST Classes - For S-expression conditions
#==============================================================================

# Base class for all conditions
package FSM::AST::Condition {
    our @ISA = ('FSM::AST::Node');
    
    sub new($class, %args) {
        my $self = bless {}, $class;
        return $self;
    }
    
    # Override in subclasses to generate HDL boolean expressions
    sub to_hdl($self, $target_lang = 'vhdl') {
        die "to_hdl not implemented in " . ref($self);
    }
    
    # For complex condition analysis 
    sub get_signals($self) {
        return [];
    }
}

# Comparison condition: signal OP value (e.g., enable = '1')
package FSM::AST::ComparisonCondition {
    our @ISA = ('FSM::AST::Condition');
    
    sub new($class, %args) {
        my $self = bless {
            signal => $args{signal} // die "signal required",
            operator => $args{operator} // '=',
            value => $args{value} // die "value required",
            slice => $args{slice} // undef,  # For signal[i:j] 
        }, $class;
        return $self;
    }
    
    sub to_hdl($self, $target_lang = 'vhdl') {
        my $signal = $self->{signal} // 'unknown_signal';
        $signal .= $self->{slice} if $self->{slice};
        
        my $op = $self->{operator} // '=';
        my $value = $self->{value} // '0';
        
        # VHDL operators
        if ($target_lang eq 'vhdl') {
            $op = '/=' if $op eq '!=';
            return "$signal $op $value";
        }
        
        # SystemVerilog operators  
        if ($target_lang eq 'systemverilog') {
            return "$signal $op $value";
        }
        
        return "$signal $op $value";
    }
    
    sub get_signals($self) {
        return [$self->{signal}];
    }
}

# Logical condition: (AND/OR/NOT conditions)
package FSM::AST::LogicalCondition {
    our @ISA = ('FSM::AST::Condition');
    
    sub new($class, %args) {
        my $self = bless {
            operator => $args{operator} // die "operator required (AND/OR/NOT)",
            operands => $args{operands} // [],
        }, $class;
        return $self;
    }
    
    sub add_operand($self, $condition) {
        push $self->{operands}->@*, $condition;
    }
    
    sub to_hdl($self, $target_lang = 'vhdl') {
        my @operand_hdl = map { $_->to_hdl($target_lang) } $self->{operands}->@*;
        
        given ($self->{operator}) {
            when ('AND') { return '(' . join(' AND ', @operand_hdl) . ')' }
            when ('OR')  { return '(' . join(' OR ', @operand_hdl) . ')' }
            when ('NOT') { return 'NOT(' . $operand_hdl[0] . ')' }
            default { die "Unknown logical operator: $self->{operator}" }
        }
    }
    
    sub get_signals($self) {
        my @signals;
        for my $operand ($self->{operands}->@*) {
            push @signals, $operand->get_signals->@*;
        }
        return \@signals;
    }
}

# S-expression condition from parsed Lisp-like expressions
package FSM::AST::SExprCondition {
    our @ISA = ('FSM::AST::Condition');
    
    sub new($class, %args) {
        my $self = bless {
            sexpr => $args{sexpr} // die "sexpr required",
            parsed_condition => undef,  # Will hold parsed AST
        }, $class;
        
        $self->{parsed_condition} = $self->_parse_sexpr($self->{sexpr});
        return $self;
    }
    
    # Parse S-expression into condition AST
    sub _parse_sexpr($self, $sexpr) {
        # Handle simple comparisons like "enable=1"  
        if (!ref $sexpr && $sexpr =~ /^(\w+)\s*([=!<>]+)\s*(.+)$/) {
            return FSM::AST::ComparisonCondition->new(
                signal => $1,
                operator => $2, 
                value => $3
            );
        }
        
        # Handle array references for complex S-expressions
        if (ref $sexpr eq 'ARRAY') {
            my ($op, @args) = $sexpr->@*;
            
            # Logical operators
            given ($op) {
                when ('&')  { return $self->_parse_logical_op('AND', \@args) }
                when ('|')  { return $self->_parse_logical_op('OR', \@args) }
                when ('!')  { return $self->_parse_logical_op('NOT', \@args) }
                when ('!=') { 
                    # Handle != as NOT(=)
                    die "!= requires exactly 2 args" unless @args == 2;
                    return FSM::AST::LogicalCondition->new(
                        operator => 'NOT',
                        operands => [FSM::AST::ComparisonCondition->new(
                            signal => $args[0],
                            operator => '=',
                            value => $args[1]
                        )]
                    );
                }
                default {
                    # Direct comparison operators  
                    die "Comparison requires exactly 2 args" unless @args == 2;
                    return FSM::AST::ComparisonCondition->new(
                        signal => $args[0],
                        operator => $op,
                        value => $args[1]
                    );
                }
            }
        }
        
        die "Cannot parse S-expression: " . ($sexpr // 'undef');
    }
    
    sub _parse_logical_op($self, $op, $args) {
        my @conditions;
        for my $arg ($args->@*) {
            push @conditions, $self->_parse_sexpr($arg);
        }
        
        return FSM::AST::LogicalCondition->new(
            operator => $op,
            operands => \@conditions
        );
    }
    
    sub to_hdl($self, $target_lang = 'vhdl') {
        return $self->{parsed_condition}->to_hdl($target_lang);
    }
    
    sub get_signals($self) {
        return $self->{parsed_condition}->get_signals;
    }
}

#==============================================================================
# Enhanced Assignment - Now supports conditional execution
#==============================================================================

package FSM::AST::ConditionalAssignment {
    our @ISA = ('FSM::AST::Assignment');
    
    sub new($class, %args) {
        # Force language-agnostic design by only accepting AST conditions
        if ($args{condition} && !ref($args{condition})) {
            die "ConditionalAssignment: String conditions not allowed. Use condition_ast with AST objects for language-agnostic design.";
        }
        
        my $self = $class->SUPER::new(%args);
        
        # Add condition support - only AST objects
        $self->{assignment_type} = $args{assignment_type} // 'signal'; # signal, register, state
        
        return $self;
    }
    
    sub has_condition($self) {
        return defined $self->{condition_ast};
    }
    
    # Legacy method - deprecated to enforce AST usage
    sub condition($self) {
        warn "condition() is deprecated. Use condition_ast() with AST objects for language-agnostic design.";
        return $self->{condition_ast};
    }
    
    sub assignment_type($self) {
        return $self->{assignment_type};
    }
    
    # Generate language-agnostic HDL with condition
    sub to_hdl($self, $target_lang = 'vhdl') {
        my $target = $self->{target} // 'unknown_target';
        my $expression = $self->{expression} // '0';
        my $assignment = "$target <= $expression";
        
        if ($self->has_condition) {
            my $condition_hdl = $self->{condition_ast}->to_hdl($target_lang);
            
            if ($target_lang eq 'vhdl') {
                return "if $condition_hdl then\n    $assignment;\nend if;";
            } elsif ($target_lang eq 'systemverilog') {
                return "if ($condition_hdl)\n    $assignment;";  
            }
        }
        
        return $assignment;
    }
}

#==============================================================================
# Enhanced State Transition - Conditional state changes
#==============================================================================

package FSM::AST::ConditionalTransition {
    our @ISA = ('FSM::AST::Transition');
    
    sub new($class, %args) {
        # Force language-agnostic design by only accepting AST conditions
        if ($args{condition} && !ref($args{condition})) {
            die "ConditionalTransition: String conditions not allowed. Use condition_ast with AST objects for language-agnostic design.";
        }
        
        my $self = $class->SUPER::new(%args);
        return $self;
    }
    
    sub has_condition_ast($self) {
        return defined $self->{condition_ast};
    }
    
    sub condition_ast($self) {
        return $self->{condition_ast};
    }
    
    sub to_hdl($self, $target_lang = 'vhdl') {
        my $target_state = $self->{target_state} // 'UNKNOWN_STATE';
        
        if ($self->has_condition_ast) {
            my $condition_hdl = $self->{condition_ast}->to_hdl($target_lang);
            return "if $condition_hdl then\n    next_state <= $target_state;\nend if;";
        }
        
        # Fallback - just the transition
        return "next_state <= $target_state;";
    }
    
    sub get_condition_signals($self) {
        return $self->{condition_ast} ? $self->{condition_ast}->get_signals : [];
    }
}

#==============================================================================
# Decision Tree Node - Represents S-expression decision trees
#==============================================================================

package FSM::AST::DecisionTree {
    our @ISA = ('FSM::AST::Node');
    
    sub new($class, %args) {
        my $self = bless {
            condition => $args{condition} // die "condition required",
            branches => $args{branches} // [], # Array of decision branches
        }, $class;
        return $self;
    }
    
    sub add_branch($self, $value, $actions) {
        push $self->{branches}->@*, {
            value => $value,      # The value to match (e.g., '1', '0', 'idle')
            actions => $actions   # Array of assignments/transitions to execute
        };
    }
    
    sub condition($self) { return $self->{condition} }
    sub branches($self) { return $self->{branches} }
    
    # Generate VHDL case statement
    sub to_vhdl_case($self) {
        my $signal = $self->{condition}->get_signals->[0];
        my $vhdl = "case $signal is\n";
        
        for my $branch ($self->{branches}->@*) {
            $vhdl .= "    when $branch->{value} =>\n";
            for my $action ($branch->{actions}->@*) {
                if (ref($action) && ($action->can('to_hdl') || $action->can('target'))) {
                    if ($action->can('to_hdl')) {
                        my $action_hdl = $action->to_hdl('vhdl');
                        $vhdl .= "        $action_hdl\n";
                    } else {
                        # Simple assignment fallback
                        my $target = $action->can('target') ? $action->target : 'unknown';
                        my $expr = $action->can('expression') ? $action->expression : '0';
                        $vhdl .= "        $target <= $expr;\n";
                    }
                }
            }
        }
        
        $vhdl .= "    when others =>\n";
        $vhdl .= "        null;\n";
        $vhdl .= "end case;\n";
        
        return $vhdl;
    }
}

#==============================================================================
# Enhanced State - Supports decision trees and conditional assignments
#==============================================================================

package FSM::AST::EnhancedState {
    our @ISA = ('FSM::AST::State');
    
    sub new($class, %args) {
        my $self = $class->SUPER::new(%args);
        
        # Add decision tree support
        $self->{decision_trees} = [];
        
        return $self;
    }
    
    sub add_decision_tree($self, $decision_tree) {
        push $self->{decision_trees}->@*, $decision_tree;
    }
    
    sub decision_trees($self) {
        return $self->{decision_trees};
    }
    
    # Enhanced assignment that can be conditional
    sub add_conditional_assignment($self, $assignment) {
        if ($assignment->isa('FSM::AST::ConditionalAssignment')) {
            $self->add_assignment($assignment);
        } else {
            # Convert regular assignment to conditional
            my $cond_assignment = FSM::AST::ConditionalAssignment->new(
                target => $assignment->target,
                expression => $assignment->expression,
                condition => undef  # No condition
            );
            $self->add_assignment($cond_assignment);
        }
    }
    
    # Enhanced transition that can be conditional
    sub add_conditional_transition($self, $transition) {
        if ($transition->isa('FSM::AST::ConditionalTransition')) {
            $self->add_transition($transition);
        } else {
            # Convert regular transition to conditional
            my $cond_transition = FSM::AST::ConditionalTransition->new(
                target_state => $transition->target_state,
                condition_ast => undef  # No condition 
            );
            $self->add_transition($cond_transition);
        }
    }
}

#==============================================================================
# S-expression Evaluator and Utilities  
#==============================================================================

package FSM::AST::SExprEvaluator {
    
    # Parse S-expression from array or string
    sub parse_condition($sexpr) {
        return FSM::AST::SExprCondition->new(sexpr => $sexpr);
    }
    
    # Create simple comparison conditions
    sub create_comparison($signal, $op, $value) {
        return FSM::AST::ComparisonCondition->new(
            signal => $signal,
            operator => $op,
            value => $value
        );
    }
    
    # Create logical conditions
    sub create_logical($op, @conditions) {
        return FSM::AST::LogicalCondition->new(
            operator => $op,
            operands => \@conditions
        );
    }
    
    # Parse your FSMGen.pm style test expressions
    sub parse_testnode($test_expr) {
        # Handle (?signal (=value1 actions1) (=value2 actions2))
        if ($test_expr =~ /^\?(\w+)/) {
            my $signal = $1;
            
            my $tree = FSM::AST::DecisionTree->new(
                condition => FSM::AST::ComparisonCondition->new(
                    signal => $signal,
                    operator => '=', 
                    value => "test_value"  # This would be parsed from full expression
                )
            );
            
            return $tree;
        }
        
        return undef;
    }
}

#==============================================================================
# Maintain backward compatibility by exporting original classes
#==============================================================================

# Re-export original classes for compatibility
package FSM::AST::Node {
    sub new($class, %args) {
        return bless \%args, $class;
    }
}

package FSM::AST::Module {
    our @ISA = ('FSM::AST::Node');
    
    sub new($class, %args) {
        my $self = bless {
            name => $args{name} // die "Module name required",
            ports => [],
            signals => [],
            states => [],
        }, $class;
        return $self;
    }
    
    sub name($self) { return $self->{name} }
    sub ports($self) { return $self->{ports} }
    sub signals($self) { return $self->{signals} }
    sub states($self) { return $self->{states} }
    
    sub add_port($self, $port) { push $self->{ports}->@*, $port }
    sub add_signal($self, $signal) { push $self->{signals}->@*, $signal }
    sub add_state($self, $state) { push $self->{states}->@*, $state }
}

package FSM::AST::Port {
    our @ISA = ('FSM::AST::Node');
    
    sub new($class, %args) {
        my $self = bless {
            name => $args{name} // die "Port name required",
            direction => $args{direction} // 'in',
            port_type => $args{port_type} // 'std_logic',
            width => $args{width} // 1,
        }, $class;
        return $self;
    }
    
    sub name($self) { return $self->{name} }
    sub direction($self) { return $self->{direction} }
    sub port_type($self) { return $self->{port_type} }
    sub width($self) { return $self->{width} }
    
    sub is_input($self) { return $self->{direction} eq 'in' }
    sub is_output($self) { return $self->{direction} eq 'out' }
}

package FSM::AST::Signal {
    our @ISA = ('FSM::AST::Node');
    
    sub new($class, %args) {
        my $self = bless {
            name => $args{name} // die "Signal name required",
            width => $args{width} // 1,
            signal_type => $args{signal_type} // 'std_logic',
        }, $class;
        return $self;
    }
    
    sub name($self) { return $self->{name} }
    sub width($self) { return $self->{width} }
    sub signal_type($self) { return $self->{signal_type} }
}

package FSM::AST::State {
    our @ISA = ('FSM::AST::Node');
    
    sub new($class, %args) {
        my $self = bless {
            name => $args{name} // die "State name required",
            is_reset_state => $args{is_reset_state} // 0,
            assignments => [],
            transitions => [],
        }, $class;
        return $self;
    }
    
    sub name($self) { return $self->{name} }
    sub is_reset_state($self) { return $self->{is_reset_state} }
    sub assignments($self) { return $self->{assignments} }
    sub transitions($self) { return $self->{transitions} }
    
    sub add_assignment($self, $assignment) { push $self->{assignments}->@*, $assignment }
    sub add_transition($self, $transition) { push $self->{transitions}->@*, $transition }
}

package FSM::AST::Assignment {
    our @ISA = ('FSM::AST::Node');
    
    sub new($class, %args) {
        my $self = bless {
            target => $args{target} // die "Assignment target required",
            expression => $args{expression} // die "Assignment expression required",
            condition_ast => $args{condition_ast},  # Only AST conditions allowed
        }, $class;
        
        # Reject any string-based condition to maintain language agnostic design
        if ($args{condition} && !ref($args{condition})) {
            die "String-based conditions not allowed. Use condition_ast with AST objects to remain language-agnostic.";
        }
        
        return $self;
    }
    
    sub target($self) { return $self->{target} }
    sub expression($self) { return $self->{expression} }
    sub condition_ast($self) { return $self->{condition_ast} }
    
    sub has_condition($self) {
        return defined $self->{condition_ast};
    }
    
    # Generate language-agnostic HDL
    sub to_hdl($self, $target_lang = 'vhdl') {
        my $target = $self->{target} // 'unknown_target';
        my $expression = $self->{expression} // '0';
        my $assignment = "$target <= $expression";
        
        if ($self->has_condition) {
            my $condition_hdl = $self->{condition_ast}->to_hdl($target_lang);
            
            if ($target_lang eq 'vhdl') {
                return "if $condition_hdl then\n    $assignment;\nend if;";
            } elsif ($target_lang eq 'systemverilog') {
                return "if ($condition_hdl)\n    $assignment;";
            }
        }
        
        return $assignment;
    }
}

package FSM::AST::Transition {
    our @ISA = ('FSM::AST::Node');
    
    sub new($class, %args) {
        my $self = bless {
            target_state => $args{target_state} // die "Target state required",
            condition_ast => $args{condition_ast},  # Only AST conditions allowed
        }, $class;
        
        # Reject string-based conditions to maintain language agnostic design
        if ($args{condition} && !ref($args{condition})) {
            die "String-based conditions not allowed. Use condition_ast with AST objects to remain language-agnostic.";
        }
        
        return $self;
    }
    
    sub target_state($self) { return $self->{target_state} }
    sub condition_ast($self) { return $self->{condition_ast} }
    
    # Legacy method for backward compatibility - but warns against string usage
    sub condition($self) { 
        warn "condition() is deprecated. Use condition_ast() with AST objects for language-agnostic design.";
        return $self->{condition_ast};
    }
    
    sub has_condition($self) {
        return defined $self->{condition_ast};
    }
    
    # Generate language-agnostic representation
    sub to_hdl($self, $target_lang = 'vhdl') {
        my $target_state = $self->{target_state} // 'UNKNOWN_STATE';
        
        if ($self->has_condition) {
            my $condition_hdl = $self->{condition_ast}->to_hdl($target_lang);
            
            if ($target_lang eq 'vhdl') {
                return "if $condition_hdl then\n    next_state <= $target_state;\nend if;";
            } elsif ($target_lang eq 'systemverilog') {
                return "if ($condition_hdl)\n    next_state <= $target_state;";
            }
        }
        
        # Unconditional transition
        if ($target_lang eq 'vhdl') {
            return "next_state <= $target_state;";
        } elsif ($target_lang eq 'systemverilog') {
            return "next_state <= $target_state;";
        }
        
        return "next_state <= $target_state;";  # Default fallback
    }
}

1;

__END__

=head1 NAME

FSM::ASTv2 - Enhanced FSM Abstract Syntax Tree with S-expression Condition Support

=head1 SYNOPSIS

    use FSM::ASTv2;
    
    # Create conditions from S-expressions
    my $condition = FSM::AST::SExprCondition->new(
        sexpr => ['&', 'enable=1', 'timer>10']
    );
    
    # Create conditional assignments  
    my $assignment = FSM::AST::ConditionalAssignment->new(
        target => 'counter',
        expression => 'counter + 1',
        condition => $condition
    );
    
    # Create decision trees
    my $tree = FSM::AST::DecisionTree->new(
        condition => FSM::AST::ComparisonCondition->new(
            signal => 'state',
            operator => '=', 
            value => 'IDLE'
        )
    );

=head1 DESCRIPTION

This enhanced version of FSM::AST adds support for S-expression based conditions,
conditional assignments, and decision trees as used in your original FSMGen.pm.

Key features:
- S-expression condition parsing and evaluation
- Conditional assignments and state transitions
- Decision tree support for complex FSM logic
- HDL generation for VHDL and SystemVerilog
- Backward compatibility with existing FSM::AST usage

=cut
