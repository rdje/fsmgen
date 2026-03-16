package FSM::Adapter::FSMGenFull::SignalAnalyzer;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';
use Data::Dumper;
use FSM::CoreAST;
use FSM::Debug;

sub new($class, %args) {
    Carp::confess "SignalAnalyzer requires signal_manager" unless $args{signal_manager};
    
    return bless {
        debug => $args{debug} // 0,
        signal_manager => $args{signal_manager},
    }, $class;
}

sub analyze_signal_roles($self, $fsm_module) {
    fsm_debug("\n=== PHASE 2: Analyzing Signal Roles ===", 3);
    
    return unless $fsm_module;
    
    $self->_analyze_signal_usage_from_ast($fsm_module);
    
    my $registry = $self->{signal_manager}->{signal_registry};
    my $usage_map = $self->{signal_manager}->get_all_signal_usages();
    
    for my $signal_name (keys %$registry) {
        next if !exists $usage_map->{$signal_name};
        
        my $usage = $usage_map->{$signal_name};
        my $signal = $registry->{$signal_name};
        
        my $role = $self->_classify_signal_role($fsm_module, $signal_name, $usage);
        $signal->set_attribute('signal_role', $role);
        
        my $contexts_str = join(',', @{$usage->{contexts} || []});
        fsm_debug("  Signal '$signal_name': $role (refs:$usage->{referenced_in_conditions}, assigns:$usage->{assigned_to}, output_marker:$usage->{has_output_marker}, intermediate:$usage->{is_intermediate}, contexts:[$contexts_str])", 3);
    }
}

sub _analyze_signal_usage_from_ast($self, $fsm_module) {
    fsm_debug("  Analyzing signal usage from complete AST...", 3);
    
    my $states = $fsm_module->states || [];
    my $state_count = scalar(@$states);
    fsm_debug("  Found $state_count states in FSM module", 3);
    
    for my $state (@$states) {
        my $dts = $state->decision_trees || [];
        for my $dt (@$dts) {
            $self->_analyze_decision_tree($dt);
        }
    }
}

sub _analyze_decision_tree($self, $dt) {
    my $elements = $dt->elements();
    if ($elements && ref($elements) eq 'ARRAY') {
        my $element_count = scalar(@$elements);
        fsm_debug("    DECISION TREE: Found $element_count elements", 3);
        
        for my $element (@$elements) {
            fsm_debug("      ANALYZING ELEMENT: Type = " . ref($element), 3);
            $self->_analyze_ast_element($element);
        }
    } else {
        fsm_debug("    DECISION TREE: No elements found", 3);
    }
}

sub _analyze_ast_element($self, $element) {
    if ($element->isa('FSM::CoreAST::ConditionalBranch')) {
        $self->_analyze_condition_references($element->condition);
        
        for my $branch ($element->branches->@*) {
            for my $action ($branch->{actions}->@*) {
                $self->_analyze_action_element($action);
            }
        }
    } elsif ($element->isa('FSM::CoreAST::TestNode')) {
        $self->_analyze_test_signal_reference($element->test_signal, 'TEST_NODE');
        
        my $branches = $element->test_branches;
        if ($branches && ref($branches) eq 'ARRAY') {
            for my $branch (@$branches) {
                for my $action (@{$branch->{actions}}) {
                    $self->_analyze_action_element($action);
                }
            }
        }
    } else {
        $self->_analyze_action_element($element);
    }
}

sub _analyze_condition_references($self, $condition) {
    return unless $condition;
    
    if ($condition->isa('FSM::CoreAST::SignalRef')) {
        $self->_analyze_signal_ref_usage($condition->signal, 'CONDITION');
    } elsif ($condition->isa('FSM::CoreAST::BinaryOp')) {
        $self->_analyze_condition_references($condition->left) if $condition->left;
        $self->_analyze_condition_references($condition->right) if $condition->right;
    } elsif ($condition->isa('FSM::CoreAST::UnaryOp')) {
        $self->_analyze_condition_references($condition->operand) if $condition->operand;
    }
}

sub _analyze_action_element($self, $action) {
    return unless $action;
    
    fsm_debug("    ACTION ELEMENT: Type = " . ref($action), 3);
    
    if ($action->isa('FSM::CoreAST::Assignment') || $action->isa('FSM::CoreAST::RegisterAssignment')) {
        if ($action->target && $action->target->isa('FSM::CoreAST::SignalRef')) {
            my $signal_name = $action->target->signal->name;
            my $usage = $self->{signal_manager}->initialize_signal_usage($signal_name);
            $usage->{assigned_to}++;
            push @{$usage->{contexts}}, 'LHS';
            fsm_debug("    SIGNAL ASSIGNMENT: '$signal_name' in context 'LHS' (total assigns: $usage->{assigned_to})", 3);
        }
        
        if ($action->source) {
            $self->_analyze_expression_references($action->source, 'RHS');
        }
    } elsif ($action->isa('FSM::CoreAST::ConditionalBranch')) {
        $self->_analyze_ast_element($action);
    } elsif ($action->isa('FSM::CoreAST::TestNode')) {
        $self->_analyze_test_signal_reference($action->test_signal, 'TEST_NODE');
        
        my $branches = $action->test_branches;
        if ($branches && ref($branches) eq 'ARRAY') {
            for my $branch (@$branches) {
                for my $branch_action (@{$branch->{actions}}) {
                    $self->_analyze_action_element($branch_action);
                }
            }
        }
    } elsif ($action->isa('FSM::CoreAST::StateTransition')) {
        fsm_debug("    STATE TRANSITION: -> $action->{target_state}", 3);
    }
}

sub _analyze_test_signal_reference($self, $signal, $context = 'TEST_NODE') {
    return unless $signal;

    $self->_analyze_signal_ref_usage($signal, $context);
}

sub _analyze_expression_references($self, $expr, $context = 'RHS') {
    return unless $expr;
    
    fsm_debug("    EXPRESSION ANALYSIS: Type = " . ref($expr) . " in context '$context'", 3);
    
    if ($expr->isa('FSM::CoreAST::SignalRef')) {
        $self->_analyze_signal_ref_usage($expr->signal, $context);
    } elsif ($expr->isa('FSM::CoreAST::BinaryOp')) {
        $self->_analyze_expression_references($expr->left, "$context.left") if $expr->left;
        $self->_analyze_expression_references($expr->right, "$context.right") if $expr->right;
    } elsif ($expr->isa('FSM::CoreAST::UnaryOp')) {
        $self->_analyze_expression_references($expr->operand, "$context.unary") if $expr->operand;
    } elsif ($expr->isa('FSM::CoreAST::Literal')) {
        # Nothing
    } elsif ($expr->isa('FSM::CoreAST::IndexedRef')) {
        if ($expr->signal) {
            my $signal_name = $expr->signal->name;
            my $usage = $self->{signal_manager}->initialize_signal_usage($signal_name);
            $usage->{referenced_in_conditions}++;
            push @{$usage->{contexts}}, "$context.indexed";
        }
        $self->_analyze_expression_references($expr->index, "$context.index") if $expr->index;
    }
}

sub _analyze_signal_ref_usage($self, $signal, $context) {
    return unless $signal;

    my $signal_name = $signal->name;
    my $usage = $self->{signal_manager}->initialize_signal_usage($signal_name);
    $usage->{referenced_in_conditions}++;
    push @{$usage->{contexts}}, $context;
    fsm_debug("    SIGNAL REFERENCE: '$signal_name' in context '$context' (total refs: $usage->{referenced_in_conditions})", 3);

    if ($signal->can('driving_ast') && $signal->driving_ast) {
        $self->_analyze_expression_references($signal->driving_ast, "$context.driving_ast");
    }
}

sub _classify_signal_role($self, $fsm_module, $signal_name, $usage) {
    if ($usage->{is_intermediate}) {
        return 'INTERNAL_INTERMEDIATE';
    }

    if ($usage->{has_output_marker}) {
        return 'OUTPUT';
    }

    if ($fsm_module
            && $fsm_module->can('is_dt_root')
            && $fsm_module->is_dt_root
            && $usage->{assigned_to} > 0) {
        return 'OUTPUT';
    }
    
    if ($usage->{referenced_in_conditions} > 0 && $usage->{assigned_to} == 0) {
        return 'INPUT';
    }
    
    if ($usage->{assigned_to} > 0 && !$usage->{has_output_marker}) {
        return 'INTERNAL';
    }
    
    return 'INTERNAL_DEFAULT';
}

sub generate_fsm_interface($self, $fsm_module) {
    fsm_debug("\n=== Generating FSM Interface ===", 3);
    
    return unless $fsm_module;
    
    my $input_count = 0;
    my $output_count = 0;
    my $internal_count = 0;
    my $intermediate_count = 0;
    
    my $registry = $self->{signal_manager}->{signal_registry};
    
    for my $signal_name (sort keys %$registry) {
        my $signal = $registry->{$signal_name};
        my $role = $signal->get_attribute('signal_role') || 'UNKNOWN';
        
        if ($role eq 'INPUT') {
            $fsm_module->add_signal($signal);
            $input_count++;
            fsm_debug("  Added INPUT: $signal_name", 3);
        } elsif ($role eq 'OUTPUT') {
            $signal->set_attribute('is_output', 1);
            $fsm_module->add_signal($signal);
            $output_count++;
            fsm_debug("  Added OUTPUT: $signal_name", 3);
        } elsif ($role eq 'INTERNAL_INTERMEDIATE') {
            $fsm_module->add_signal($signal);
            $intermediate_count++;
            fsm_debug("  Added INTERMEDIATE signal to FSM module: $signal_name", 3);
        } else {
            $internal_count++;
            fsm_debug("  Kept INTERNAL: $signal_name (role: $role)", 3);
        }
    }
    
    fsm_debug("\nFSM Interface Summary:", 3);
    fsm_debug("  Inputs: $input_count", 3);
    fsm_debug("  Outputs: $output_count", 3);
    fsm_debug("  Intermediates (internal): $intermediate_count", 3);
    fsm_debug("  Other Internal: $internal_count", 3);
}

1;
