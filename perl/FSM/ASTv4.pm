package FSM::ASTv4;

# FSM AST with Revolutionary Decision Tree Architecture
# Multiple states can be simultaneously active in the same clock cycle!

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef switch);
no warnings qw(experimental::signatures experimental::postderef experimental::smartmatch);

#==============================================================================
# Revolutionary Decision Tree Architecture
# Decision Trees are NOT mapped 1:1 to FSM states!
# Multiple Decision Trees can be active simultaneously!
#==============================================================================

# Decision Tree: Independent control entity that can be active in parallel with others
package FSM::AST::DecisionTree {
    our @ISA = ('FSM::AST::Node');
    
    sub new($class, %args) {
        # Validate required arguments
        die "dt_name required" unless defined $args{dt_name};
        die "enable_condition required" unless defined $args{enable_condition};
        
        my $self = bless {
            # Unique identifier for this Decision Tree
            dt_name => $args{dt_name},
            
            # The 1-bit controlling condition (driven by logical-OR)
            enable_condition => $args{enable_condition},
            
            # All signals/ports this DT can control via WENs
            controlled_targets => [],  # Array of controllable targets
            
            # All WEN-controlled actions in this DT
            wen_actions => [],
            
            # Meta information
            description => $args{description} // "Decision Tree: " . $args{dt_name},
        }, $class;
        return $self;
    }
    
    sub dt_name($self) { return $self->{dt_name} }
    sub enable_condition($self) { return $self->{enable_condition} }
    sub description($self) { return $self->{description} }
    
    # Add a target that this DT can control
    sub add_controlled_target($self, $target) {
        push $self->{controlled_targets}->@*, $target;
    }
    
    # Get all controlled targets
    sub controlled_targets($self) { return $self->{controlled_targets} }
    
    # Add a WEN-controlled action
    sub add_wen_action($self, $action) {
        push $self->{wen_actions}->@*, $action;
        # Auto-register the target as controlled by this DT
        $self->add_controlled_target($action->target) unless grep { $_ eq $action->target } $self->{controlled_targets}->@*;
    }
    
    sub wen_actions($self) { return $self->{wen_actions} }
    
    # Generate all WEN signals for this DT
    # Critical: When enable_condition = 0, ALL WENs = 0 immediately (combinational)
    # When enable_condition = 1, each WEN computed from specific conditions
    sub generate_wens($self, $target_lang = 'vhdl') {
        my @wen_signals;
        
        # Safety check for enable_condition
        if (!$self->{enable_condition}) {
            die "Decision Tree '$self->{dt_name}' has no enable_condition";
        }
        
        my $dt_enable_hdl = $self->{enable_condition}->to_hdl($target_lang);
        my $dt_name = $self->{dt_name};
        
        for my $action ($self->{wen_actions}->@*) {
            my $wen_signal = $action->generate_wen($dt_enable_hdl, $dt_name, $target_lang);
            push @wen_signals, $wen_signal;
        }
        
        return \@wen_signals;
    }
    
    # Check if this DT can be simultaneously active with another DT
    # (They can be active together if they don't control the same targets)
    sub can_be_concurrent_with($self, $other_dt) {
        my %my_targets = map { $_ => 1 } $self->{controlled_targets}->@*;
        my %other_targets = map { $_ => 1 } $other_dt->{controlled_targets}->@*;
        
        # Check for conflicts
        for my $target (keys %my_targets) {
            return 0 if exists $other_targets{$target};  # Conflict!
        }
        
        return 1;  # No conflicts - can run concurrently
    }
    
    # Analyze all signals this DT reads
    sub get_read_signals($self) {
        my @signals;
        
        # Get signals from enable condition
        if ($self->{enable_condition} && $self->{enable_condition}->can('get_signals')) {
            my $condition_signals = $self->{enable_condition}->get_signals;
            push @signals, @$condition_signals if $condition_signals;
        }
        
        # Get signals from actions
        for my $action ($self->{wen_actions}->@*) {
            if ($action->can('get_signals')) {
                my $action_signals = $action->get_signals;
                push @signals, @$action_signals if $action_signals;
            }
        }
        
        return \@signals;
    }
}

#==============================================================================
# Enhanced WEN Actions - Support DT-specific naming
#==============================================================================

# Base class for all WEN-controlled actions
package FSM::AST::WenAction {
    our @ISA = ('FSM::AST::Node');
    
    sub new($class, %args) {
        my $self = bless {
            action_condition => $args{action_condition},
            target => $args{target} // die "target required",
            action_type => $args{action_type} // die "action_type required",
        }, $class;
        return $self;
    }
    
    sub target($self) { return $self->{target} }
    sub action_type($self) { return $self->{action_type} }
    
    # Generate WEN signal with DT-specific naming
    # WEN = DT_enable AND action_condition
    sub generate_wen($self, $dt_enable_hdl, $dt_name, $target_lang = 'vhdl') {
        my $wen_name = $self->get_wen_name($dt_name);
        
        if ($self->{action_condition}) {
            my $action_cond = $self->{action_condition}->to_hdl($target_lang);
            return "$wen_name <= $dt_enable_hdl AND ($action_cond);";
        } else {
            # No specific condition - just follows DT enable
            return "$wen_name <= $dt_enable_hdl;";
        }
    }
    
    # Get DT-specific WEN signal name
    sub get_wen_name($self, $dt_name) {
        return "${dt_name}_" . $self->{target} . "_wen";
    }
    
    sub get_signals($self) {
        return $self->{action_condition} ? $self->{action_condition}->get_signals : [];
    }
}

# Flop Control Action - Can control any flop (not just state flops)
package FSM::AST::FlopControlAction {
    our @ISA = ('FSM::AST::WenAction');
    
    sub new($class, %args) {
        my $self = $class->SUPER::new(%args);
        $self->{next_value} = $args{next_value} // die "next_value required";
        $self->{flop_type} = $args{flop_type} // 'internal';
        return $self;
    }
    
    sub next_value($self) { return $self->{next_value} }
    sub flop_type($self) { return $self->{flop_type} }
    
    # Generate mux control for ANY flop
    sub generate_mux_control($self, $dt_name, $target_lang = 'vhdl') {
        my $target = $self->{target};
        my $next_value = $self->{next_value};
        my $wen_name = $self->get_wen_name($dt_name);
        
        if ($target_lang eq 'vhdl') {
            return "next_$target <= $next_value when $wen_name = '1' else $target;";
        } elsif ($target_lang eq 'systemverilog') {
            return "assign next_$target = $wen_name ? $next_value : $target;";
        }
        
        return "next_$target = $wen_name ? $next_value : $target;";
    }
}

# Combinational Signal Control - Controls internal/output combinational signals
package FSM::AST::CombinatorialControlAction {
    our @ISA = ('FSM::AST::WenAction');
    
    sub new($class, %args) {
        my $self = $class->SUPER::new(%args);
        $self->{signal_value} = $args{signal_value} // die "signal_value required";
        return $self;
    }
    
    sub signal_value($self) { return $self->{signal_value} }
    
    # Generate control for combinational signal
    # signal = signal_value AND WEN  (for outputs)
    # or signal = signal_value when WEN='1' else '0'  (for internal)
    sub generate_signal_control($self, $dt_name, $target_lang = 'vhdl') {
        my $target = $self->{target};
        my $signal_value = $self->{signal_value};
        my $wen_name = $self->get_wen_name($dt_name);
        
        if ($self->{action_type} eq 'output') {
            # Output ports use AND gate
            if ($target_lang eq 'vhdl') {
                return "$target <= $signal_value AND $wen_name;";
            } elsif ($target_lang eq 'systemverilog') {
                return "assign $target = $signal_value & $wen_name;";
            }
        } else {
            # Internal signals use conditional assignment
            if ($target_lang eq 'vhdl') {
                return "$target <= $signal_value when $wen_name = '1' else '0';";
            } elsif ($target_lang eq 'systemverilog') {
                return "assign $target = $wen_name ? $signal_value : '0';";
            }
        }
        
        return "$target = $signal_value & $wen_name;";
    }
}

#==============================================================================
# Revolutionary FSM Module - Supports Multiple Concurrent Decision Trees
#==============================================================================

package FSM::AST::ConcurrentFSM {
    our @ISA = ('FSM::AST::Node');
    
    sub new($class, %args) {
        my $self = bless {
            name => $args{name} // die "Module name required",
            ports => [],
            signals => [],
            
            # Revolutionary: Collection of independent Decision Trees
            # Multiple can be active simultaneously!
            decision_trees => [],
            
            # Track initial states (can have multiple!)
            initial_decision_trees => [],
        }, $class;
        return $self;
    }
    
    sub name($self) { return $self->{name} }
    sub ports($self) { return $self->{ports} }
    sub signals($self) { return $self->{signals} }
    sub decision_trees($self) { return $self->{decision_trees} }
    sub initial_decision_trees($self) { return $self->{initial_decision_trees} }
    
    sub add_port($self, $port) { push $self->{ports}->@*, $port }
    sub add_signal($self, $signal) { push $self->{signals}->@*, $signal }
    
    # Add a Decision Tree to the FSM
    sub add_decision_tree($self, $dt, $is_initial = 0) {
        push $self->{decision_trees}->@*, $dt;
        
        if ($is_initial) {
            push $self->{initial_decision_trees}->@*, $dt;
        }
    }
    
    # Analyze which DTs can run concurrently
    sub analyze_concurrency($self) {
        my @dts = $self->{decision_trees}->@*;
        my %concurrent_groups;
        
        for my $i (0 .. $#dts) {
            for my $j ($i+1 .. $#dts) {
                my $dt1 = $dts[$i];
                my $dt2 = $dts[$j];
                
                if ($dt1->can_be_concurrent_with($dt2)) {
                    push @{$concurrent_groups{$dt1->dt_name}}, $dt2->dt_name;
                    push @{$concurrent_groups{$dt2->dt_name}}, $dt1->dt_name;
                }
            }
        }
        
        return \%concurrent_groups;
    }
    
    # Generate all WEN signals for all Decision Trees
    sub generate_all_wens($self, $target_lang = 'vhdl') {
        my @all_wens;
        
        for my $dt ($self->{decision_trees}->@*) {
            my $dt_wens = $dt->generate_wens($target_lang);
            push @all_wens, @$dt_wens;
        }
        
        return \@all_wens;
    }
    
    # Analyze signal flow across all Decision Trees
    sub analyze_signal_flow($self) {
        my %signal_readers;  # Which DTs read each signal
        my %signal_writers;  # Which DTs write each signal
        
        for my $dt ($self->{decision_trees}->@*) {
            my $dt_name = $dt->dt_name;
            
            # Signals this DT reads
            for my $signal ($dt->get_read_signals->@*) {
                push @{$signal_readers{$signal}}, $dt_name;
            }
            
            # Signals this DT controls/writes
            for my $target ($dt->controlled_targets->@*) {
                push @{$signal_writers{$target}}, $dt_name;
            }
        }
        
        return {
            readers => \%signal_readers,
            writers => \%signal_writers
        };
    }
    
    # Find potential conflicts (multiple DTs writing to same target)
    sub find_conflicts($self) {
        my $signal_flow = $self->analyze_signal_flow;
        my @conflicts;
        
        for my $signal (keys %{$signal_flow->{writers}}) {
            my $writers = $signal_flow->{writers}{$signal};
            if (@$writers > 1) {
                push @conflicts, {
                    signal => $signal,
                    conflicting_dts => $writers
                };
            }
        }
        
        return \@conflicts;
    }
}

#==============================================================================
# Re-export condition classes
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

# Comparison condition
package FSM::AST::ComparisonCondition {
    our @ISA = ('FSM::AST::Condition');
    
    sub new($class, %args) {
        die "signal required" unless defined $args{signal};
        die "value required" unless defined $args{value};
        
        my $self = bless {
            signal => $args{signal},
            operator => $args{operator} // '=',
            value => $args{value},
            slice => $args{slice},
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
        
        return "$signal $op $value";
    }
    
    sub get_signals($self) {
        return [$self->{signal}];
    }
}

# Logical condition
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
# Compatibility classes
#==============================================================================

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
}

1;

__END__

=head1 NAME

FSM::ASTv4 - Revolutionary FSM AST with Concurrent Decision Trees

=head1 SYNOPSIS

    use FSM::ASTv4;
    
    # Create independent Decision Trees
    my $dt1 = FSM::AST::DecisionTree->new(
        dt_name => "counter_control",
        enable_condition => $main_enable_condition
    );
    
    my $dt2 = FSM::AST::DecisionTree->new(
        dt_name => "led_blink",  
        enable_condition => $blink_enable_condition
    );
    
    # Both can be active simultaneously!
    my $fsm = FSM::AST::ConcurrentFSM->new(name => "concurrent_controller");
    $fsm->add_decision_tree($dt1, 1);  # Initial state
    $fsm->add_decision_tree($dt2, 1);  # Also initial state!

=head1 DESCRIPTION

Revolutionary FSM architecture where:
- Decision Trees are independent control entities
- Multiple Decision Trees can be simultaneously active
- FSMs can have multiple initial states
- Each DT has one controlling condition (logical-OR)
- DTs control flops/outputs via WEN signals
- Concurrent execution when no target conflicts

=cut
