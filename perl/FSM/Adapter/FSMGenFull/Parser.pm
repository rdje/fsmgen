package FSM::Adapter::FSMGenFull::Parser;

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
    Carp::confess "Parser requires signal_manager" unless $args{signal_manager};
    Carp::confess "Parser requires expression_builder" unless $args{expression_builder};
    
    return bless {
        debug => $args{debug} // 0,
        signal_manager => $args{signal_manager},
        expression_builder => $args{expression_builder},
        fsm_module => undef,
    }, $class;
}

sub get_fsm_module($self) {
    return $self->{fsm_module};
}

sub parse_fsm($self, $raw_ast) {
    fsm_debug("Starting full FSMGen parsing", 3);
    
    if (ref($raw_ast) eq 'ARRAY') {
        if (@$raw_ast > 0 && !ref($raw_ast->[0]) && $raw_ast->[0] =~ /^\?fsm:/) {
            return $self->parse_fsm_module($raw_ast);
        }
        
        if (@$raw_ast > 0 && ref($raw_ast->[0]) eq 'ARRAY' && $raw_ast->[0][0] eq '+fsm') {
            return $self->parse_fsm_module(['root_array', $raw_ast], 1);
        }
        
        for my $ast_node (@$raw_ast) {
            if (ref($ast_node) eq 'ARRAY' && @$ast_node > 0 && !ref($ast_node->[0]) && $ast_node->[0] =~ /^\?fsm:/) {
                return $self->parse_fsm_module($ast_node);
            }
        }
    }
    
    Carp::confess "Expected FSM structure containing '?fsm:name' or '+fsm'";
}

sub parse_fsm_module($self, $fsm_ast, $is_flat_ast = 0) {
    my $module_name;
    my $fsm_contents;
    
    if ($is_flat_ast) {
        my $ast_array = $fsm_ast->[1];
        my $fsm_header = $ast_array->[0];
        $module_name = $fsm_header->[1][0];
        $fsm_contents = $ast_array;
    } else {
        my ($fsm_header, $contents) = @$fsm_ast;
        ($module_name) = $fsm_header =~ /\?fsm:(\w+)/;
        $fsm_contents = $contents;
    }
    
    fsm_debug("Parsing FSM module: $module_name", 3);
    
    my $module = FSM::CoreAST::FSMModule->new(name => $module_name);
    $self->{fsm_module} = $module;
    
    for my $element (@$fsm_contents) {
        next unless ref($element) eq 'ARRAY';
        my $element_name = $element->[0];
        
        if ($element_name eq '+fsm') {
            next;
        } elsif ($element_name eq '+system') {
            next;
        } elsif ($element_name eq '+size') {
            fsm_debug("Parsing +size block", 3);
            if (ref($element->[1]) eq 'ARRAY') {
                for my $size_def (@{$element->[1]}) {
                    my ($sig, $width) = @$size_def;
                    $self->{signal_manager}->register_signal($sig, width => $width->[0]);
                }
            }
        } elsif ($element_name eq '+constants') {
            fsm_debug("Parsing constants section", 3);
            $self->parse_constants_section($element);
        } elsif ($element_name eq '+enums') {
            fsm_debug("Parsing enums section", 3);
            $self->parse_enums_section($element);
        } elsif ($element_name eq '+define') {
            fsm_debug("Parsing define directive", 3);
            $self->parse_define_directive($element);
        } elsif ($element_name eq '+params') {
            fsm_debug("Parsing params section", 3);
            $self->parse_params_section($element);
        } elsif ($element_name =~ /^[a-zA-Z_]/ && $element_name !~ /^(idle|-syncrst|-asyncrst)$/ && !ref($element->[1])) {
            next;
        } else {
            fsm_debug("Parsing state block: $element_name", 3);
            my $state = $self->parse_state($element);
            $module->add_state($state) if $state;
        }
    }
    
    return $module;
}

sub parse_constants_section($self, $constants_ast) {
    my (undef, $constants_list) = @$constants_ast;
    for my $constant_def (@$constants_list) {
        my ($name, $value) = @$constant_def;
        my $literal_expr = $self->{expression_builder}->parse_scalar_expression($value);
        $self->{signal_manager}->store_constant($name, $literal_expr);
    }
}

sub parse_enums_section($self, $enums_ast) {
    my (undef, $enums_list) = @$enums_ast;
    for my $enum_def (@$enums_list) {
        my ($enum_name, $members_list) = @$enum_def;
        my %enum_values;
        for my $member_def (@$members_list) {
            my ($member_name, $member_value_array) = @$member_def;
            $enum_values{$member_name} = $member_value_array->[0];
        }
        $self->{signal_manager}->store_enum($enum_name, \%enum_values);
    }
}

sub parse_define_directive($self, $define_ast) {
    my (undef, $define_spec) = @$define_ast;
    my ($name, $value) = @$define_spec;
    my $value_expr = $self->{expression_builder}->parse_scalar_expression($value);
    $self->{signal_manager}->store_define($name, $value_expr);
}

sub parse_params_section($self, $params_ast) {
    my (undef, $params_list) = @$params_ast;
    for my $param_def (@$params_list) {
        my ($name, $value_array) = @$param_def;
        $self->{signal_manager}->store_param($name, $value_array->[0]);
    }
}


sub parse_state($self, $state_ast) {
    my ($state_name, $decision_trees) = @$state_ast;
    
    my $state_type = 'normal';
    my $clean_name = $state_name;
    
    if ($state_name eq '-syncrst') {
        $state_type = 'sync_reset';
        $clean_name = 'syncreset';
    } elsif ($state_name eq '-asyncrst') {
        $state_type = 'async_reset';
        $clean_name = 'asyncreset';
    }
    
    my $state = FSM::CoreAST::State->new(
        name => $clean_name,
        state_type => $state_type
    );
    $self->{current_state} = $state;
    
    my @trees;
    if (ref($decision_trees) eq 'ARRAY' && @$decision_trees > 0 && ref($decision_trees->[0]) eq 'ARRAY') {
        @trees = @$decision_trees;
    } elsif (ref($decision_trees) eq 'ARRAY') {
        @trees = ($decision_trees);
    }
    
    for my $tree (@trees) {
        if (ref($tree) eq 'ARRAY') {
            my $dt = $self->parse_decision_tree($tree);
            $state->add_decision_tree($dt) if $dt;
        }
    }
    
    return $state;
}

sub parse_decision_tree($self, $tree_ast) {
    my $dt = FSM::CoreAST::DecisionTree->new(name => 'main_dt');
    
    my @elements_to_parse;
    if (ref($tree_ast->[0]) eq 'ARRAY') {
        @elements_to_parse = @$tree_ast;
    } else {
        @elements_to_parse = ($tree_ast);
    }
    
    for my $element (@elements_to_parse) {
        my $parsed_action = $self->parse_action($element);
        if ($parsed_action) {
            $dt->add_element($parsed_action);
        }
    }
    
    return $dt;
}

sub parse_action($self, $action) {
    return undef unless ref($action) eq 'ARRAY' && @$action >= 2;
    
    my ($action_target, $action_spec) = @$action;
    fsm_debug("      Parsing action: $action_target", 3);
    
    if ($action_target eq '->') {
        return $self->parse_transition_new_format($action);
    } elsif ($action_target =~ /^\?/) {
        return $self->parse_test_node_new_format($action);
    } elsif ($action_target =~ /^[<>]/) {
        return $self->parse_nested_condition_new_format($action);
    } elsif (ref($action_spec) eq 'ARRAY' && @$action_spec >= 2) {
        return $self->parse_signal_action($action);
    } else {
        fsm_debug("        Unknown action format: $action_target -> " . ref($action_spec), 3);
        return undef;
    }
}

sub parse_transition_new_format($self, $action) {
    my (undef, $target_spec) = @$action;
    
    my $target_state;
    my $condition_suffix;
    
    if (ref($target_spec) eq 'ARRAY') {
        $target_state = $target_spec->[0];
        $condition_suffix = $target_spec->[1] if @$target_spec > 1;
    } else {
        $target_state = $target_spec;
    }
    
    my $transition = FSM::CoreAST::StateTransition->new(
        target_state => $target_state,
        transition_type => 'goto'
    );
    
    if (defined $condition_suffix) {
        my $condition_expr = $self->{expression_builder}->parse_condition($condition_suffix);
        if ($condition_expr) {
            return FSM::CoreAST::ConditionalBranch->new(
                condition => $condition_expr,
                branches => [{
                    condition => $condition_expr,
                    actions => [$transition]
                }]
            );
        }
    }
    
    return $transition;
}

sub parse_test_node_new_format($self, $action) {
    my ($test_signal, $branches) = @$action;
    
    my $signal;
    if ($test_signal eq '?') {
        # Format: (?(| a b) (=0 x))
        # The condition expression is the first element of branches
        my $cond_ast = shift @$branches;
        my $condition_expr = $self->{expression_builder}->parse_condition($cond_ast);
        
        if ($condition_expr && $condition_expr->isa('FSM::CoreAST::SignalRef')) {
            $signal = $condition_expr->signal;
        } else {
            # Need to create an intermediate signal for this complex condition
            my $intermediate_name = $self->{expression_builder}->generate_intermediate_signal('cond', [$condition_expr || FSM::CoreAST::Literal->new('0')]);
            $signal = $self->{signal_manager}->register_signal($intermediate_name, 
                type => 'wire',
                is_intermediate => 1
            );
            $signal->set_attribute('driving_ast', $condition_expr) if $condition_expr;
        }
    } else {
        # Format: (?is_last (=0 x))
        my ($signal_name) = $test_signal =~ /^\?(.+)/;
        $signal = $self->{signal_manager}->register_signal($signal_name);
    }
    
    my $test_node = FSM::CoreAST::TestNode->new(test_signal => $signal);
    
    if (ref($branches) eq 'ARRAY') {
        for my $branch (@$branches) {
            if (ref($branch) eq 'ARRAY' && @$branch >= 2) {
                my ($test_value, @branch_actions) = @$branch;
                my @parsed_actions;
                
                for my $branch_action (@branch_actions) {
                    if (ref($branch_action) eq 'ARRAY') {
                        if (@$branch_action > 0 && ref($branch_action->[0]) eq 'ARRAY') {
                            for my $nested_assignment (@$branch_action) {
                                my $parsed_action = $self->parse_action($nested_assignment);
                                push @parsed_actions, $parsed_action if $parsed_action;
                            }
                        } else {
                            my $parsed_action = $self->parse_action($branch_action);
                            push @parsed_actions, $parsed_action if $parsed_action;
                        }
                    } else {
                        my $parsed_action = $self->parse_action($branch_action);
                        push @parsed_actions, $parsed_action if $parsed_action;
                    }
                }
                $test_node->add_test_branch($test_value, \@parsed_actions);
            }
        }
    }
    
    return $test_node;
}

sub parse_nested_condition_new_format($self, $action) {
    my ($condition, $nested_actions) = @$action;
    
    my $condition_expr = $self->{expression_builder}->parse_condition($condition);
    
    my @parsed_actions;
    if (ref($nested_actions) eq 'ARRAY') {
        for my $nested_action (@$nested_actions) {
            my $parsed_action = $self->parse_action($nested_action);
            push @parsed_actions, $parsed_action if $parsed_action;
        }
    }
    
    if ($condition_expr && @parsed_actions) {
        return FSM::CoreAST::ConditionalBranch->new(
            condition => $condition_expr,
            branches => [{
                condition => $condition_expr,
                actions => \@parsed_actions
            }]
        );
    }
    
    return undef;
}

sub parse_signal_action($self, $action) {
    my ($signal_name, $operation_spec) = @$action;
    return undef unless ref($operation_spec) eq 'ARRAY' && @$operation_spec >= 2;
    
    my ($operator, $value_expr, $condition_suffix, $condition_expr) = @$operation_spec;
    
    my $full_condition;
    if ($condition_suffix && $condition_suffix eq '<' && ref($condition_expr) eq 'ARRAY') {
        $full_condition = $condition_expr;
    } elsif ($condition_suffix) {
        $full_condition = $condition_suffix;
    }

    my $target_expr = $self->{expression_builder}->parse_signal_reference($signal_name);
    my $source_expr = $self->{expression_builder}->parse_expression($value_expr);

    my ($lhs_width, $rhs_width, $final_width);
    my ($lhs_explicit, $rhs_explicit) = (0, 0);

    if ($signal_name =~ /'(\d+)$/) {
        $lhs_width = $1;
        $lhs_explicit = 1;
    } elsif (ref($target_expr) eq 'FSM::CoreAST::SignalRef' && $target_expr->slice) {
        my ($high, $low) = @{$target_expr->slice};
        $lhs_width = abs($high - $low) + 1;
        $lhs_explicit = 1;
    } elsif (ref($target_expr) eq 'FSM::CoreAST::IndexedRef') {
        $lhs_width = 1;
        $lhs_explicit = 1;
    } elsif (ref($target_expr) eq 'FSM::CoreAST::SignalRef' && $target_expr->signal && $target_expr->signal->width && $target_expr->signal->width > 1) {
        $lhs_width = $target_expr->signal->width;
        $lhs_explicit = 1;
    }

    if ($source_expr && $source_expr->can('width') && $source_expr->width) {
        $rhs_width = $source_expr->width;
        $rhs_explicit = 1;
    } elsif (ref($source_expr) eq 'FSM::CoreAST::SignalRef' && $source_expr->slice) {
        my ($high, $low) = @{$source_expr->slice};
        $rhs_width = abs($high - $low) + 1;
        $rhs_explicit = 1;
    } elsif (ref($source_expr) eq 'FSM::CoreAST::IndexedRef') {
        $rhs_width = 1;
        $rhs_explicit = 1;
    } elsif (ref($source_expr) eq 'FSM::CoreAST::SignalRef' && $source_expr->signal && $source_expr->signal->width && $source_expr->signal->width > 1) {
        $rhs_width = $source_expr->signal->width;
        $rhs_explicit = 1;
    }

    if ($lhs_explicit && $rhs_explicit) {
        if ($lhs_width != $rhs_width) {
            $self->{expression_builder}->handle_width_mismatch($lhs_width, $rhs_width, $signal_name, $value_expr, \$source_expr);
        }
        $final_width = $lhs_width;
    } elsif ($lhs_explicit) {
        $final_width = $lhs_width;
        $self->{expression_builder}->propagate_width_to_expression($source_expr, $final_width);
    } elsif ($rhs_explicit) {
        $final_width = $rhs_width;
        $self->{expression_builder}->propagate_width_to_expression($target_expr, $final_width);
    } else {
        $final_width = 1;
    }

    if ($final_width && ref($target_expr) eq 'FSM::CoreAST::SignalRef' && !$target_expr->slice) {
        my $signal = $target_expr->signal;
        if ($signal && (!$signal->width || $signal->width == 1) && $final_width > 1) {
            $self->{signal_manager}->register_signal($signal->name, width => $final_width);
        }
    }
    
    $target_expr = $self->{expression_builder}->parse_signal_reference($signal_name); 

    my $assignment;
    if ($operator eq '<-') {
        $assignment = FSM::CoreAST::RegisterAssignment->new(
            target => $target_expr,
            source => $source_expr,
            assignment_type => 'clocked',
            register_style => 'output_named'
        );
    } elsif ($operator eq '<=') {
        $assignment = FSM::CoreAST::RegisterAssignment->new(
            target => $target_expr,
            source => $source_expr,
            assignment_type => 'clocked',
            register_style => 'input_named'
        );
    } elsif ($operator eq '=') {
        $assignment = FSM::CoreAST::Assignment->new(
            target => $target_expr,
            source => $source_expr,
            assignment_type => 'combinational'
        );
    } else {
        return undef;
    }
    
    if (defined $full_condition) {
        my $condition_expr = $self->{expression_builder}->parse_condition($full_condition);
        if ($condition_expr) {
            return FSM::CoreAST::ConditionalBranch->new(
                condition => $condition_expr,
                branches => [{
                    condition => $condition_expr,
                    actions => [$assignment]
                }]
            );
        }
    }
    
    return $assignment;
}

1;
