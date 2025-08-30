package FSM::ASTv3;

# FSM AST with Decision Trees as Core Principle
# Each state has exactly one Decision Tree that controls all behavior

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef switch);
no warnings qw(experimental::signatures experimental::postderef experimental::smartmatch);

#==============================================================================
# Decision Tree - The Core Principle
#==============================================================================

# Decision Tree: Controls all flop behavior via WENs (Write Enable signals)
package FSM::AST::DecisionTree {
    our @ISA = ('FSM::AST::Node');
    
    sub new($class, %args) {
        my $self = bless {
            # The master enable condition for this entire DT
            enable_condition => $args{enable_condition} // die "enable_condition required",
            
            # All WEN-controlled actions in this DT
            # Each action generates a WEN signal that controls muxes/and-gates
            wen_actions => [],  # Array of WEN-controlled actions
            
            # Meta information
            state_name => $args{state_name},  # Which state this DT belongs to
            dt_index => $args{dt_index} // 0, # For multiple DTs (future extension)
        }, $class;
        return $self;
    }
    
    # The master enable condition (logical-OR of various sources)
    sub enable_condition($self) { return $self->{enable_condition} }
    sub set_enable_condition($self, $condition) { $self->{enable_condition} = $condition }
    
    # Add a WEN-controlled action to this DT
    sub add_wen_action($self, $action) {
        push $self->{wen_actions}->@*, $action;
    }
    
    # Get all WEN actions
    sub wen_actions($self) { return $self->{wen_actions} }
    
    # Generate the WEN signals for this DT
    # When enable_condition = 0, ALL WENs go to 0 immediately (combinationally)
    # When enable_condition = 1, each WEN is computed based on its specific condition
    sub generate_wens($self, $target_lang = 'vhdl') {
        my @wen_signals;
        my $dt_enable = $self->{enable_condition}->to_hdl($target_lang);
        
        for my $action ($self->{wen_actions}->@*) {
            my $wen_signal = $action->generate_wen($dt_enable, $target_lang);
            push @wen_signals, $wen_signal;
        }
        
        return \@wen_signals;
    }
    
    # Analyze all signals used by this DT
    sub get_all_signals($self) {
        my @signals = $self->{enable_condition}->get_signals->@*;
        
        for my $action ($self->{wen_actions}->@*) {
            push @signals, $action->get_signals->@*;
        }
        
        return \@signals;
    }
}

#==============================================================================
# WEN Actions - Actions controlled by Decision Tree WENs
#==============================================================================

# Base class for all WEN-controlled actions
package FSM::AST::WenAction {
    our @ISA = ('FSM::AST::Node');
    
    sub new($class, %args) {
        my $self = bless {
            # The condition for this specific action (within the DT)
            action_condition => $args{action_condition},
            
            # Action details
            target => $args{target} // die "target required",
            action_type => $args{action_type} // die "action_type required", # 'flop', 'output', 'internal'
        }, $class;
        return $self;
    }
    
    # Generate the WEN signal for this action
    # WEN = DT_enable AND action_condition
    sub generate_wen($self, $dt_enable, $target_lang = 'vhdl') {
        my $wen_name = $self->get_wen_name();
        
        if ($self->{action_condition}) {
            my $action_cond = $self->{action_condition}->to_hdl($target_lang);
            return "$wen_name <= $dt_enable AND ($action_cond);";
        } else {
            # No specific condition - just follows DT enable
            return "$wen_name <= $dt_enable;";
        }
    }
    
    # Get the WEN signal name for this action
    sub get_wen_name($self) {
        return $self->{target} . "_wen";
    }
    
    # Get all signals used by this action
    sub get_signals($self) {
        return $self->{action_condition} ? $self->{action_condition}->get_signals : [];
    }
}

# Flop Control Action - Controls mux selection for flops (states, internal flops)
package FSM::AST::FlopControlAction {
    our @ISA = ('FSM::AST::WenAction');
    
    sub new($class, %args) {
        my $self = $class->SUPER::new(%args);
        
        # What value to load into the flop when WEN is high
        $self->{next_value} = $args{next_value} // die "next_value required for flop control";
        $self->{flop_type} = $args{flop_type} // 'internal'; # 'state', 'internal', 'output'
        
        return $self;
    }
    
    # Generate the mux control logic
    # The WEN controls which input to the mux is selected
    sub generate_mux_control($self, $target_lang = 'vhdl') {
        my $target = $self->{target};
        my $next_value = $self->{next_value};
        my $wen_name = $self->get_wen_name();
        
        if ($target_lang eq 'vhdl') {
            return "next_$target <= $next_value when $wen_name = '1' else $target;";
        } elsif ($target_lang eq 'systemverilog') {
            return "assign next_$target = $wen_name ? $next_value : $target;";
        }
        
        return "next_$target = $wen_name ? $next_value : $target;";
    }
}

# Output Control Action - Controls combinational outputs via AND gates
package FSM::AST::OutputControlAction {
    our @ISA = ('FSM::AST::WenAction');
    
    sub new($class, %args) {
        my $self = $class->SUPER::new(%args);
        
        # The output value when WEN is high
        $self->{output_value} = $args{output_value} // die "output_value required for output control";
        
        return $self;
    }
    
    # Generate the AND gate control logic
    # output = output_value AND WEN
    sub generate_output_control($self, $target_lang = 'vhdl') {
        my $target = $self->{target};
        my $output_value = $self->{output_value};
        my $wen_name = $self->get_wen_name();
        
        if ($target_lang eq 'vhdl') {
            return "$target <= $output_value AND $wen_name;";
        } elsif ($target_lang eq 'systemverilog') {
            return "assign $target = $output_value & $wen_name;";
        }
        
        return "$target = $output_value & $wen_name;";
    }
}

# State Transition Action - Special flop control for FSM state
package FSM::AST::StateTransitionAction {
    our @ISA = ('FSM::AST::FlopControlAction');
    
    sub new($class, %args) {
        # Ensure next_value is set before calling parent
        my $target_state = $args{target_state} // die "target_state required";
        
        my $self = $class->SUPER::new(
            %args,
            next_value => $target_state,  # Pass next_value to parent
            flop_type => 'state',
            target => 'current_state'  # State flop is always called current_state
        );
        
        # Store the target state
        $self->{target_state} = $target_state;
        
        return $self;
    }
    
    sub target_state($self) { return $self->{target_state} }
}

#==============================================================================
# Enhanced State with Single Decision Tree
#==============================================================================

package FSM::AST::DTState {
    our @ISA = ('FSM::AST::Node');
    
    sub new($class, %args) {
        my $self = bless {
            name => $args{name} // die "State name required",
            is_reset_state => $args{is_reset_state} // 0,
            
            # Each state has exactly ONE Decision Tree
            decision_tree => undef,
        }, $class;
        return $self;
    }
    
    sub name($self) { return $self->{name} }
    sub is_reset_state($self) { return $self->{is_reset_state} }
    
    # Set the single Decision Tree for this state
    sub set_decision_tree($self, $dt) {
        $self->{decision_tree} = $dt;
        $dt->{state_name} = $self->{name};  # Link DT to state
    }
    
    # Get the Decision Tree
    sub decision_tree($self) { return $self->{decision_tree} }
    
    # Convenience methods to add actions to the state's DT
    sub add_flop_control($self, $action) {
        die "No decision tree set for state $self->{name}" unless $self->{decision_tree};
        $self->{decision_tree}->add_wen_action($action);
    }
    
    sub add_output_control($self, $action) {
        die "No decision tree set for state $self->{name}" unless $self->{decision_tree};
        $self->{decision_tree}->add_wen_action($action);
    }
    
    sub add_state_transition($self, $action) {
        die "No decision tree set for state $self->{name}" unless $self->{decision_tree};
        $self->{decision_tree}->add_wen_action($action);
    }
}

#==============================================================================
# Re-export condition classes from ASTv2
#==============================================================================

# Base class for all conditions
package FSM::AST::Condition {
    our @ISA = ('FSM::AST::Node');
    
    sub new($class, %args) {
        my $self = bless {}, $class;
        return $self;
    }
    
    sub to_hdl($self, $target_lang = 'vhdl') {
        die "to_hdl not implemented in " . ref($self);
    }
    
    sub get_signals($self) {
        return [];
    }
}

# Comparison condition: signal OP value  
package FSM::AST::ComparisonCondition {
    our @ISA = ('FSM::AST::Condition');
    
    sub new($class, %args) {
        my $self = bless {
            signal => $args{signal} // die "signal required",
            operator => $args{operator} // '=',
            value => $args{value} // die "value required",
            slice => $args{slice} // undef,
        }, $class;
        return $self;
    }
    
    sub to_hdl($self, $target_lang = 'vhdl') {
        my $signal = $self->{signal} // 'unknown_signal';
        $signal .= $self->{slice} if $self->{slice};
        
        my $op = $self->{operator} // '=';
        my $value = $self->{value} // '0';
        
        if ($target_lang eq 'vhdl') {
            $op = '/=' if $op eq '!=';
            return "$signal $op $value";
        }
        
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

#==============================================================================
# Enhanced FSM Module with Decision Tree Architecture  
#==============================================================================

package FSM::AST::DTModule {
    our @ISA = ('FSM::AST::Node');
    
    sub new($class, %args) {
        my $self = bless {
            name => $args{name} // die "Module name required",
            ports => [],
            signals => [],
            states => [],  # Array of DTState objects
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
    
    # Generate all WEN signals for the entire FSM
    sub generate_all_wens($self, $target_lang = 'vhdl') {
        my @all_wens;
        
        for my $state ($self->{states}->@*) {
            if ($state->decision_tree) {
                my $wens = $state->decision_tree->generate_wens($target_lang);
                push @all_wens, @$wens;
            }
        }
        
        return \@all_wens;
    }
    
    # Analyze signal dependencies across all DTs
    sub analyze_signal_dependencies($self) {
        my %signal_usage;
        
        for my $state ($self->{states}->@*) {
            if ($state->decision_tree) {
                my $signals = $state->decision_tree->get_all_signals;
                for my $signal (@$signals) {
                    push @{$signal_usage{$signal}}, $state->name;
                }
            }
        }
        
        return \%signal_usage;
    }
}

#==============================================================================
# Compatibility classes
#==============================================================================

# Re-export other necessary classes for compatibility
package FSM::AST::Node {
    sub new($class, %args) {
        return bless \%args, $class;
    }
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

1;

__END__

=head1 NAME

FSM::ASTv3 - FSM AST with Decision Trees as Core Principle

=head1 SYNOPSIS

    use FSM::ASTv3;
    
    # Create a Decision Tree with master enable condition
    my $dt = FSM::AST::DecisionTree->new(
        enable_condition => FSM::AST::LogicalCondition->new(
            operator => 'OR',
            operands => [$main_input_condition, $other_fsm_condition]
        )
    );
    
    # Add WEN-controlled actions to the DT
    $dt->add_wen_action(FSM::AST::FlopControlAction->new(
        target => 'counter',
        next_value => 'counter + 1',
        action_condition => $enable_condition
    ));
    
    # Create state with single DT
    my $state = FSM::AST::DTState->new(name => 'RUNNING');
    $state->set_decision_tree($dt);

=head1 DESCRIPTION

This version implements the core principle: Decision Trees control everything.

Key concepts:
- Each state has exactly ONE Decision Tree  
- DT has a master enable condition (logical-OR of various sources)
- When enable = 0, ALL WENs go to 0 immediately (combinationally)
- WENs control muxes for flops and AND gates for combinational outputs
- DT controls flop behavior by controlling mux selection

=cut
