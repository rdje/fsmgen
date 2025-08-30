package FSM::ASTv5;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);
use POSIX qw(log);

# Signal representation
package FSM::ASTv5::Signal {
    use v5.20;
    use feature qw(signatures postderef);
    no warnings qw(experimental::signatures experimental::postderef);

    sub new($class, %args) {
        my $self = {
            name => $args{name} // die "Signal name required",
            width => $args{width} // 1,
            type => $args{type} // 'wire',  # wire, reg, input, output
            range => $args{range},           # [high:low] or undef for single bit
            value => $args{value},           # constant value if applicable
        };
        return bless $self, $class;
    }

    sub name($self) { $self->{name} }
    sub width($self) { $self->{width} }
    sub type($self) { $self->{type} }
    sub range($self) { $self->{range} }
    sub value($self) { $self->{value} }

    sub to_hdl($self) {
        my $name = $self->name;
        if (defined $self->range) {
            return "$name" . "[" . $self->range . "]";
        }
        return $name;
    }
}

# Condition representation for S-expressions
package FSM::ASTv5::Condition {
    use v5.20;
    use feature qw(signatures postderef);
    no warnings qw(experimental::signatures experimental::postderef);

    sub new($class, %args) {
        die "Abstract class - use subclasses";
    }

    sub to_hdl($self) {
        die "Must implement to_hdl in subclass";
    }

    sub get_signals($self) {
        die "Must implement get_signals in subclass";
    }
}

# Simple signal condition (just a signal name)
package FSM::ASTv5::SignalCondition {
    our @ISA = qw(FSM::ASTv5::Condition);
    use v5.20;
    use feature qw(signatures postderef);
    no warnings qw(experimental::signatures experimental::postderef);

    sub new($class, $signal) {
        die "Signal required" unless defined $signal;
        my $self = { signal => $signal };
        return bless $self, $class;
    }

    sub signal($self) { $self->{signal} }

    sub to_hdl($self) {
        my $sig = $self->signal;
        if (ref $sig) {
            return $sig->to_hdl;
        }
        return $sig;
    }

    sub get_signals($self) {
        my $sig = $self->signal;
        return ref $sig ? [$sig] : [];
    }
}

# Comparison condition (signal == value, signal != value, etc.)
package FSM::ASTv5::ComparisonCondition {
    our @ISA = qw(FSM::ASTv5::Condition);
    use v5.20;
    use feature qw(signatures postderef);
    no warnings qw(experimental::signatures experimental::postderef);

    sub new($class, $signal, $operator, $value) {
        die "Signal, operator, and value required" unless defined $signal && defined $operator && defined $value;
        my $self = {
            signal => $signal,
            operator => $operator,  # ==, !=, <, >, <=, >=
            value => $value
        };
        return bless $self, $class;
    }

    sub signal($self) { $self->{signal} }
    sub operator($self) { $self->{operator} }
    sub value($self) { $self->{value} }

    sub to_hdl($self) {
        my $sig = $self->signal;
        my $sig_hdl = ref $sig ? $sig->to_hdl : $sig;
        return "($sig_hdl " . $self->operator . " " . $self->value . ")";
    }

    sub get_signals($self) {
        my $sig = $self->signal;
        return ref $sig ? [$sig] : [];
    }
}

# Logical condition (AND, OR, NOT of other conditions)
package FSM::ASTv5::LogicalCondition {
    our @ISA = qw(FSM::ASTv5::Condition);
    use v5.20;
    use feature qw(signatures postderef);
    no warnings qw(experimental::signatures experimental::postderef);

    sub new($class, $operator, @conditions) {
        die "Operator and conditions required" unless defined $operator && @conditions;
        my $self = {
            operator => $operator,  # &, |, ||, !
            conditions => \@conditions
        };
        return bless $self, $class;
    }

    sub operator($self) { $self->{operator} }
    sub conditions($self) { $self->{conditions}->@* }

    sub to_hdl($self) {
        my $op = $self->operator;
        my @cond_hdl = map { $_->to_hdl } $self->conditions;
        
        if ($op eq '!') {
            die "NOT operator requires exactly one condition" if @cond_hdl != 1;
            return "(!$cond_hdl[0])";
        } elsif ($op eq '&') {
            return "(" . join(" & ", @cond_hdl) . ")";
        } elsif ($op eq '|' || $op eq '||') {
            return "(" . join(" | ", @cond_hdl) . ")";
        } else {
            die "Unknown logical operator: $op";
        }
    }

    sub get_signals($self) {
        my @all_signals;
        for my $cond ($self->conditions) {
            push @all_signals, $cond->get_signals;
        }
        return [@all_signals];
    }
}

# WEN Action - represents an action controlled by a Write Enable signal
package FSM::ASTv5::WenAction {
    use v5.20;
    use feature qw(signatures postderef);
    no warnings qw(experimental::signatures experimental::postderef);

    sub new($class, %args) {
        my $self = {
            wen_signal => $args{wen_signal} // die "WEN signal required",
            target => $args{target} // die "Target required",
        };
        return bless $self, $class;
    }

    sub wen_signal($self) { $self->{wen_signal} }
    sub target($self) { $self->{target} }

    sub to_hdl($self) {
        die "Must implement to_hdl in subclass";
    }
}

# Flop Control Action - controls a flip-flop via WEN
package FSM::ASTv5::FlopControlAction {
    our @ISA = qw(FSM::ASTv5::WenAction);
    use v5.20;
    use feature qw(signatures postderef);
    no warnings qw(experimental::signatures experimental::postderef);

    sub new($class, %args) {
        my $self = $class->FSM::ASTv5::WenAction::new(%args);
        $self->{next_value} = $args{next_value} // die "Next value required for flop control";
        return $self;
    }

    sub next_value($self) { $self->{next_value} }

    sub to_hdl($self) {
        my $wen = $self->wen_signal;
        my $target = $self->target;
        my $next = $self->next_value;
        return "// Flop: $target <= (${wen} ? ${next} : $target)";
    }
}

# Output Control Action - controls an output via WEN
package FSM::ASTv5::OutputControlAction {
    our @ISA = qw(FSM::ASTv5::WenAction);
    use v5.20;
    use feature qw(signatures postderef);
    no warnings qw(experimental::signatures experimental::postderef);

    sub new($class, %args) {
        my $self = $class->FSM::ASTv5::WenAction::new(%args);
        $self->{output_value} = $args{output_value} // die "Output value required";
        return $self;
    }

    sub output_value($self) { $self->{output_value} }

    sub to_hdl($self) {
        my $wen = $self->wen_signal;
        my $target = $self->target;
        my $value = $self->output_value;
        return "// Output: $target = (${wen} ? ${value} : 1'b0)";
    }
}

# State Transition Action - special case for state transitions
package FSM::ASTv5::StateTransitionAction {
    our @ISA = qw(FSM::ASTv5::FlopControlAction);
    use v5.20;
    use feature qw(signatures postderef);
    no warnings qw(experimental::signatures experimental::postderef);

    sub new($class, %args) {
        my $next_state = $args{next_state} // die "Next state required";
        return $class->FSM::ASTv5::FlopControlAction::new(
            %args,
            target => 'state_reg',  # Assumes state register is called 'state_reg'
            next_value => $next_state
        );
    }

    sub next_state($self) { $self->next_value }

    sub to_hdl($self) {
        my $wen = $self->wen_signal;
        my $next = $self->next_state;
        return "// State transition: state_reg <= (${wen} ? ${next} : state_reg)";
    }
}

# Decision Tree - One per FSM state, with exactly one enable condition
package FSM::ASTv5::DecisionTree {
    use v5.20;
    use feature qw(signatures postderef);
    no warnings qw(experimental::signatures experimental::postderef);

    sub new($class, %args) {
        my $self = {
            enable_condition => $args{enable_condition}, # Single 1-bit enable condition
            wen_actions => $args{wen_actions} // [],     # Array of WEN actions
            name => $args{name} // "unnamed_dt"
        };
        return bless $self, $class;
    }

    sub enable_condition($self) { $self->{enable_condition} }
    sub wen_actions($self) { $self->{wen_actions}->@* }
    sub name($self) { $self->{name} }

    sub set_enable_condition($self, $condition) {
        $self->{enable_condition} = $condition;
    }

    sub add_wen_action($self, $action) {
        push $self->{wen_actions}->@*, $action;
    }

    # Generate WEN signals based on enable condition
    sub generate_wen_signals($self) {
        my @wen_signals;
        my $enable_hdl = $self->enable_condition ? $self->enable_condition->to_hdl : "1'b1";
        
        for my $action ($self->wen_actions) {
            my $wen_name = $action->wen_signal;
            push @wen_signals, "assign $wen_name = $enable_hdl;";
        }
        
        return @wen_signals;
    }

    sub to_hdl($self) {
        my @hdl_lines;
        
        push @hdl_lines, "// Decision Tree: " . $self->name;
        push @hdl_lines, "// Enable condition: " . 
            ($self->enable_condition ? $self->enable_condition->to_hdl : "always enabled");
        
        # Generate WEN signals
        push @hdl_lines, $self->generate_wen_signals;
        
        # Generate actions
        for my $action ($self->wen_actions) {
            push @hdl_lines, $action->to_hdl;
        }
        
        return join("\n", @hdl_lines);
    }
}

# FSM State - Contains exactly one Decision Tree
package FSM::ASTv5::DTState {
    use v5.20;
    use feature qw(signatures postderef);
    no warnings qw(experimental::signatures experimental::postderef);

    sub new($class, %args) {
        my $name = $args{name} // die "State name required";
        my $dt_name = $name . "_dt";
        
        my $decision_tree = $args{decision_tree};
        if (!defined $decision_tree) {
            $decision_tree = FSM::ASTv5::DecisionTree->new(name => $dt_name);
        }
        
        my $self = {
            name => $name,
            decision_tree => $decision_tree,
            state_encoding => $args{state_encoding}, # Value for this state (0, 1, 2, etc.)
        };
        return bless $self, $class;
    }

    sub name($self) { $self->{name} }
    sub decision_tree($self) { $self->{decision_tree} }
    sub state_encoding($self) { $self->{state_encoding} }

    sub set_state_encoding($self, $encoding) {
        $self->{state_encoding} = $encoding;
    }

    sub to_hdl($self) {
        my @hdl_lines;
        push @hdl_lines, "// State: " . $self->name;
        if (defined $self->state_encoding) {
            push @hdl_lines, "// Encoding: " . $self->state_encoding;
        }
        push @hdl_lines, $self->decision_tree->to_hdl;
        return join("\n", @hdl_lines);
    }
}

# FSM Module - Contains states and manages state encoding
package FSM::ASTv5::FSM {
    use v5.20;
    use feature qw(signatures postderef);
    no warnings qw(experimental::signatures experimental::postderef);

    sub new($class, %args) {
        my $self = {
            name => $args{name} // die "FSM name required",
            states => $args{states} // [],
            encoding_type => $args{encoding_type} // 'encoded', # 'encoded' or 'bit_blasted'
            state_reg_width => $args{state_reg_width},
            reset_state => $args{reset_state} // 0,
        };
        return bless $self, $class;
    }

    sub name($self) { $self->{name} }
    sub states($self) { $self->{states}->@* }
    sub encoding_type($self) { $self->{encoding_type} }
    sub state_reg_width($self) { $self->{state_reg_width} }
    sub reset_state($self) { $self->{reset_state} }

    sub add_state($self, $state) {
        push $self->{states}->@*, $state;
        $self->_update_state_encodings;
    }

    # Automatically assign state encodings and set enable conditions
    sub _update_state_encodings($self) {
        my @states = $self->states;
        my $num_states = @states;
        
        # Calculate required width for encoded FSM
        if (($self->encoding_type // 'encoded') eq 'encoded') {
            my $width = $num_states <= 1 ? 1 : int(log($num_states - 1) / log(2)) + 1;
            $self->{state_reg_width} = $width;
        } else {
            # Bit-blasted: one bit per state
            $self->{state_reg_width} = $num_states;
        }
        
        # Assign encodings and create enable conditions
        for my $i (0 .. $#states) {
            my $state = $states[$i];
            $state->set_state_encoding($i);
            
            # Create appropriate enable condition based on encoding type
            my $enable_condition;
            if (($self->encoding_type // 'encoded') eq 'encoded') {
                # F == i (where F is the state register)
                $enable_condition = FSM::ASTv5::ComparisonCondition->new(
                    'state_reg', '==', $i
                );
            } else {
                # Direct bit from bit-blasted encoding
                my $state_signal = FSM::ASTv5::Signal->new(
                    name => "state_${i}_reg",
                    width => 1,
                    type => 'reg'
                );
                $enable_condition = FSM::ASTv5::SignalCondition->new($state_signal);
            }
            
            $state->decision_tree->set_enable_condition($enable_condition);
        }
    }

    sub generate_state_encoding_hdl($self) {
        my @hdl_lines;
        
        if (($self->encoding_type // 'encoded') eq 'encoded') {
            my $width = $self->state_reg_width;
            push @hdl_lines, "reg [" . ($width-1) . ":0] state_reg;";
            
            # Generate state enable signals
            for my $state ($self->states) {
                my $name = $state->name;
                my $encoding = $state->state_encoding;
                push @hdl_lines, "wire ${name}_en = (state_reg == $encoding);";
            }
        } else {
            # Bit-blasted encoding
            for my $state ($self->states) {
                my $encoding = $state->state_encoding;
                push @hdl_lines, "reg state_${encoding}_reg;";
            }
        }
        
        return @hdl_lines;
    }

    sub to_hdl($self) {
        my @hdl_lines;
        
        push @hdl_lines, "// FSM: " . $self->name;
        push @hdl_lines, "// Encoding type: " . $self->encoding_type;
        push @hdl_lines, "// State register width: " . $self->state_reg_width;
        push @hdl_lines, "";
        
        # State encoding
        push @hdl_lines, "// State encoding";
        push @hdl_lines, $self->generate_state_encoding_hdl;
        push @hdl_lines, "";
        
        # States and their decision trees
        for my $state ($self->states) {
            push @hdl_lines, $state->to_hdl;
            push @hdl_lines, "";
        }
        
        return join("\n", @hdl_lines);
    }
}

1;

__END__

=head1 NAME

FSM::ASTv5 - Corrected FSM AST with proper one-DT-per-state architecture

=head1 DESCRIPTION

This module implements the correct FSM architecture where:

- Each FSM state has exactly ONE Decision Tree (DT)
- Only ONE DT is active at any given time (traditional FSM behavior)
- State encoding can be either 'encoded' (N-bit register) or 'bit_blasted' (one bit per state)
- Each DT has exactly ONE enable condition (1-bit signal)
- Enable conditions are typically driven by state encoding, but can be OR-ed with additional conditions

=head1 ARCHITECTURE

=head2 State Encoding Options

=over 4

=item B<Encoded> (default)

Uses an N-bit register where S ≤ 2^N states are encoded as:
- state_reg == 0 → state0_en
- state_reg == 1 → state1_en  
- state_reg == 2 → state2_en
- ...

=item B<Bit-blasted>

Uses S individual 1-bit registers for S states:
- state_0_reg drives state0_en directly
- state_1_reg drives state1_en directly
- ...

=back

=head2 Decision Tree Structure

Each Decision Tree contains:
- Exactly one 1-bit enable condition
- Multiple WEN (Write Enable) actions
- WEN signals control muxes for flops, outputs, and state transitions

=head1 CLASSES

=over 4

=item B<FSM::ASTv5::FSM> - Complete FSM with states and encoding management

=item B<FSM::ASTv5::DTState> - Individual state containing one Decision Tree

=item B<FSM::ASTv5::DecisionTree> - Decision tree with enable condition and WEN actions

=item B<FSM::ASTv5::WenAction> - Base class for Write Enable controlled actions

=item B<FSM::ASTv5::Condition> - S-expression condition representation

=back

=cut
