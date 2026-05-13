package FSM::HDL::FlattenedDT::DecisionTreeFlatteningSupport;

=head1 NAME

FSM::HDL::FlattenedDT::DecisionTreeFlatteningSupport - Own recursive decision-tree flattening for the direct backend path

=head1 DESCRIPTION

Owns the bounded recursive decision-tree flattening family for the older
direct generated-module backend path. This package centralizes:

=over 4

=item *

whole-module state and standalone-DT flattening into the prepared enable and
assignment registries

=item *

the recursive traversal of conditional branches, test nodes, assignments,
transitions, arrays, and nested decision-tree containers

=item *

the final handoff into unified assignment-analysis construction once the raw
capture pass is complete

=back

The paired C<FSM::HDL::FlattenedDT::Orchestrator> now keeps per-run reset,
FSM-module attachment, and top-level generation sequencing, while this
package owns the recursive flattening step that prepares the direct backend
state before HDL text assembly begins.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;
use Scalar::Util qw(blessed);

=head2 new

Construct one decision-tree flattening owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[DecisionTreeFlatteningSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 flatten_all_decision_trees

Flatten all regular-state and standalone-DT decision trees for one FSM
module into the prepared direct-backend registries.

=cut

sub flatten_all_decision_trees ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("Flattening all decision trees", 3);
    $ctx->{enable_graph_enable_support}->initialize_state_and_dt_enable_conditions($fsm_module);

    # Process regular states first.
    for my $state (@{$fsm_module->states}) {
        next unless $state->can('is_regular_state') ? $state->is_regular_state : $state->name !~ /^-/;

        fsm_debug("Flattening state: " . $state->name, 3);

        if ($state->decision_trees && @{$state->decision_trees}) {
            for my $dt (@{$state->decision_trees}) {
                $self->flatten_decision_tree($state->name, $dt, []);
            }
        }
    }

    # Then process standalone decision trees.
    for my $state (@{$fsm_module->states}) {
        next if $state->can('is_regular_state') ? $state->is_regular_state : $state->name !~ /^-/;

        fsm_debug("Flattening standalone DT: " . $state->name, 3);

        if ($state->decision_trees && @{$state->decision_trees}) {
            for my $dt (@{$state->decision_trees}) {
                $self->flatten_decision_tree($state->name, $dt, []);
            }
        }
    }

    $ctx->{enable_graph_assignment_support}->build_unified_assignment_analysis($fsm_module);
}

=head2 flatten_decision_tree

Recursively flatten one decision-tree node into the prepared direct-backend
registries.

=cut

sub flatten_decision_tree ($self, $dt_name, $dt_node, $condition_stack) {
    my $ctx = $self->{flattened_dt};
    my $capture_support = $ctx->{enable_graph_capture_support};
    return unless $dt_node;

    fsm_debug("=== FLATTEN_DT_NODE ====", 3);
    fsm_debug("  DT: $dt_name", 3);
    fsm_debug("  Node Type: " . ref($dt_node), 3);

    my $debug_stack = "";
    if (@$condition_stack) {
        my @debug_conditions = ();
        for my $condition_ast (@$condition_stack) {
            if (blessed($condition_ast) && $condition_ast->can('to_systemverilog')) {
                push @debug_conditions, $condition_ast->to_systemverilog();
            } else {
                push @debug_conditions, ref($condition_ast) || "UNBLESSED";
            }
        }
        $debug_stack = join(", ", @debug_conditions);
    }
    fsm_debug("  Condition Stack: [$debug_stack]", 3);

    if ($dt_node->isa('FSM::CoreAST::ConditionalBranch')) {
        fsm_debug("  Conditional branch with condition: " . ($dt_node->condition ? ref($dt_node->condition) : 'none'), 3);

        my $branches = $dt_node->branches;
        for my $branch (@$branches) {
            if ($branch->{condition}) {
                my $condition_ast = $capture_support->convert_condition_to_ast($branch->{condition});
                my @new_stack = (@$condition_stack);
                push @new_stack, $condition_ast;

                my $condition_debug = blessed($condition_ast) && $condition_ast->can('to_systemverilog')
                    ? $condition_ast->to_systemverilog()
                    : (ref($condition_ast) || "UNBLESSED");
                fsm_debug("    CONDITIONAL_BRANCH: Adding condition '$condition_debug'", 3);

                my @stack_debug = map {
                    blessed($_) && $_->can('to_systemverilog')
                        ? $_->to_systemverilog()
                        : (ref($_) || "UNBLESSED")
                } @new_stack;
                fsm_debug("    New condition stack: [" . join(", ", @stack_debug) . "]", 3);

                for my $action (@{$branch->{actions}}) {
                    $self->flatten_decision_tree($dt_name, $action, \@new_stack);
                }
            } else {
                for my $action (@{$branch->{actions}}) {
                    $self->flatten_decision_tree($dt_name, $action, $condition_stack);
                }
            }
        }
    } elsif ($dt_node->isa('FSM::CoreAST::TestNode')) {
        fsm_debug("  Test node: " . $dt_node->test_signal->name, 3);

        my $test_branches = $dt_node->test_branches;
        for my $branch (@$test_branches) {
            my $test_condition_ast = $capture_support->is_default_test_selector($branch->{value})
                ? $capture_support->build_default_test_condition_ast($dt_node->test_signal, $test_branches)
                : $capture_support->build_test_condition_ast(
                    $dt_node->test_signal,
                    $branch->{value},
                );

            my @test_stack = (@$condition_stack);
            push @test_stack, $test_condition_ast;

            my $test_condition_debug = blessed($test_condition_ast) && $test_condition_ast->can('to_systemverilog')
                ? $test_condition_ast->to_systemverilog()
                : (ref($test_condition_ast) || "UNBLESSED");
            fsm_debug("    TEST_NODE: Adding test condition '$test_condition_debug'", 3);

            my @test_stack_debug = map {
                blessed($_) && $_->can('to_systemverilog')
                    ? $_->to_systemverilog()
                    : (ref($_) || "UNBLESSED")
            } @test_stack;
            fsm_debug("    New test stack: [" . join(", ", @test_stack_debug) . "]", 3);

            for my $action (@{$branch->{actions}}) {
                $self->flatten_decision_tree($dt_name, $action, \@test_stack);
            }
        }
    } elsif ($dt_node->isa('FSM::CoreAST::Assignment') || $dt_node->isa('FSM::CoreAST::RegisterAssignment')) {
        my $assignment_target_name = $capture_support->extract_signal_name_from_ast($dt_node->target) // 'unknown_lhs';
        fsm_debug("  Assignment: " . $assignment_target_name . " <- " . ref($dt_node->source), 3);
        $capture_support->capture_assignment_from_ast($dt_name, $dt_node, $condition_stack);
    } elsif ($dt_node->isa('FSM::CoreAST::StateTransition')) {
        fsm_debug("  Transition: -> " . $dt_node->target_state, 3);
        $capture_support->capture_transition_from_ast($dt_name, $dt_node, $condition_stack);
    } elsif (ref($dt_node) eq 'ARRAY') {
        for my $child (@$dt_node) {
            $self->flatten_decision_tree($dt_name, $child, $condition_stack);
        }
    } elsif ($dt_node->isa('FSM::CoreAST::DecisionTree')) {
        my $elements = $dt_node->elements;
        if ($elements && ref($elements) eq 'ARRAY') {
            fsm_debug("  DecisionTree with " . scalar(@$elements) . " elements", 3);
            for my $element (@$elements) {
                $self->flatten_decision_tree($dt_name, $element, $condition_stack);
            }
        } else {
            fsm_debug("  DecisionTree has no elements or elements is not an array", 3);
        }
    } else {
        fsm_debug("  Unknown node type: " . ref($dt_node), 3);
    }
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one decision-tree flattening owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 flatten_all_decision_trees

Flattens all regular-state and standalone-DT decision trees for one FSM
module into the prepared direct-backend registries.

=head2 flatten_decision_tree

Recursively flattens one decision-tree node into the prepared direct-backend
registries.

=cut
