package FSM::HDL::FlattenedDT::Backend::SystemVerilog::GlobalFactorizationSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::GlobalFactorizationSupport - Own the direct SystemVerilog first-pass AST factorization pipeline

=head1 DESCRIPTION

This package owns the prepared direct SystemVerilog AST-factorization pipeline
that runs before consolidated intermediate-signal emission. It centralizes:

=over 4

=item *

logical-operation count validation for the prepared backend context

=item *

first-pass AST factorizer construction and AST feed handoff

=item *

analysis, substitution, and original-AST refresh after first-pass factorization

=item *

iterative post-substitution factorization through the fixpoint owner

=item *

persistence of the live factorizer on the backend context for downstream lookup

=back

The paired C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ASTFactorizationSupport>
owner now keeps the substituted-AST lookup surface and the older direct
intermediate-signal rendering helper, while this package owns the live
first-pass factorization pipeline.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Debug;
use FSM::HDL::ASTFactorization;
use FSM::HDL::Factorization::Fixpoint;
use List::Util qw(min);

=head2 new

Construct one global-factorization support owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[GlobalFactorizationSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 run_global_ast_factorization

Run the prepared direct-backend AST-factorization pipeline over the live enable
expressions already collected in the backend context, including substitution,
original-AST refresh, fixpoint factorization, and persistence of the resulting
factorizer for downstream lookup.

=cut

sub run_global_ast_factorization ($self) {
    my $ctx = $self->{flattened_dt};
    # GENERIC AST-BASED GLOBAL FACTORIZATION
    # Uses pure AST structural analysis - works with any FSM

    fsm_debug("\n*** GENERIC GLOBAL AST FACTORIZATION PHASE ***", 3);
    fsm_debug("GLOBAL_AST_FACT: [ENTRY] Starting run_global_ast_factorization", 3);

    # TIMING FIX: Logical operations should already be counted by now!
    fsm_debug("GLOBAL_AST_FACT: [CHECK] Checking if binary_logical_op_counts exists", 3);
    if (exists $ctx->{binary_logical_op_counts}) {
        fsm_debug("GLOBAL_AST_FACT: [EXISTS] binary_logical_op_counts found", 3);
        my $total_ops = 0;
        for my $count (values %{$ctx->{binary_logical_op_counts}}) {
            $total_ops += $count;
        }
        fsm_debug("AST_FACTORIZATION: Using existing logical operation counts: $total_ops total ops", 3);
        # Show some details about operation counts
        for my $op_sig (keys %{$ctx->{binary_logical_op_counts}}) {
            my $count = $ctx->{binary_logical_op_counts}{$op_sig};
            fsm_debug("  Operation '$op_sig': $count occurrences", 3);
        }
    } else {
        fsm_debug("GLOBAL_AST_FACT: [NOT_EXISTS] binary_logical_op_counts NOT found - running count now", 3);
        fsm_warn("No logical operation counts available - this shouldn't happen!");
        $ctx->{enable_graph_factorization_policy_support}->count_binary_logical_operation_occurrences();
    }

    # Initialize generic factorizer with enhanced debugging
    my $factorizer = FSM::HDL::ASTFactorization->new(
        min_usage_count => 2,
        debug => debug_enabled(),
        debug_level => 3,
    );

    # STEP 1: Collect and add all AST expressions to factorizer
    fsm_debug("*** STEP 1: FEEDING ASTs TO FACTORIZER ***", 3);
    my $ast_count = $ctx->{enable_graph_factorization_policy_support}->feed_asts_to_factorizer($factorizer);
    fsm_debug("Fed $ast_count AST expressions to factorizer", 3);

    # Show what ASTs we have in the factorizer
    fsm_debug("Factorizer now has " . scalar(@{$factorizer->{ast_expressions}}) . " AST expressions:", 3);
    for my $i (0 .. min(9, $#{$factorizer->{ast_expressions}})) { # Show first 10
        my $expr_info = $factorizer->{ast_expressions}[$i];
        my $sv = eval { $expr_info->{ast}->to_systemverilog() } || "[NO SV REPRESENTATION]";
        fsm_debug("  [$i] Context: $expr_info->{context}", 3);
        fsm_debug("      Expression: $sv", 3);
        fsm_debug("      AST Object: " . ref($expr_info->{ast}) . " @ " . sprintf("%p", $expr_info->{ast}), 3);
    }

    # STEP 2: Perform generic analysis and factorization
    fsm_debug("*** STEP 2: PERFORMING AST ANALYSIS AND FACTORIZATION ***", 3);
    fsm_debug("*** INTERMEDIATE SIGNAL CREATION DECISION TRACKING ***", 3);
    my $result = $factorizer->analyze_and_factorize();

    fsm_debug("Analysis results:", 3);
    fsm_debug("  Total expressions: $result->{total_expressions}", 3);
    fsm_debug("  Unique structures: $result->{unique_structures}", 3);
    fsm_debug("  Factorization candidates: $result->{factorization_candidates}", 3);

    # Show the intermediate signals that were generated WITH CREATION REASONING
    my $intermediate_signals = $result->{intermediate_signals};
    if (%$intermediate_signals) {
        fsm_debug("\n*** INTERMEDIATE SIGNAL CREATION DECISIONS ***", 3);
        for my $signal_name (sort keys %$intermediate_signals) {
            my $signal_info = $intermediate_signals->{$signal_name};
            my $sv = eval { $signal_info->{ast}->to_systemverilog() } || "[NO SV REPRESENTATION]";
            my $usage = $signal_info->{usage_count};
            my $ast_ref = sprintf("%p", $signal_info->{ast});

            fsm_debug("\n=== INTERMEDIATE SIGNAL CREATED: $signal_name ===", 3);
            fsm_debug("  REASON: Expression used $usage times (threshold: 2)", 3);
            fsm_debug("  EXPRESSION: $sv", 3);
            fsm_debug("  AST_OBJECT: " . ref($signal_info->{ast}) . " @ $ast_ref", 3);
            fsm_debug("  CREATED_BY: FSM::HDL::ASTFactorization->analyze_and_factorize()", 3);

            # Show WHERE this expression was found
            if ($signal_info->{contexts}) {
                fsm_debug("  FOUND_IN_CONTEXTS:", 3);
                for my $context (@{$signal_info->{contexts}}) {
                    fsm_debug("    - $context", 3);
                }
            }
            fsm_debug("=== END INTERMEDIATE SIGNAL: $signal_name ===", 3);
        }
    } else {
        # informational note: a module that needs no factoring legitimately produces none.
        fsm_debug("no intermediate signals generated (no factoring needed)", 3);
    }

    # STEP 3: CRITICAL - Substitute intermediate signals back into original expressions
    fsm_debug("\n*** STEP 3: AST SUBSTITUTION PHASE ***", 3);
    fsm_debug("*** AST REPLACEMENT TRACKING - EVERY SUBSTITUTION WILL BE LOGGED ***", 3);
    my $substitution_count = $factorizer->substitute_expressions_with_intermediate_signals(
        $factorizer->{ast_expressions},
    );
    fsm_debug("*** AST SUBSTITUTION COMPLETE: $substitution_count expressions modified ***", 3);

    # Show detailed examples of substituted expressions with BEFORE/AFTER
    if ($substitution_count > 0) {
        fsm_debug("\n*** AST SUBSTITUTION RESULTS - SHOWING ALL CHANGES ***", 3);
        my $shown = 0;
        for my $expr_info (@{$factorizer->{ast_expressions}}) {
            my $sv = eval { $expr_info->{ast}->to_systemverilog() } || "[NO SV REPRESENTATION]";
            # Look for intermediate signal patterns - these indicate substitution occurred
            if ($sv =~ /\b\w+_and_\w+|\b\w+_or_\w+|intermediate_\d+|_expr\d*/) {
                my $context = $expr_info->{context};
                my $ast_ref = sprintf("%p", $expr_info->{ast});

                fsm_debug("\n--- SUBSTITUTED AST FOUND ---", 3);
                fsm_debug("  CONTEXT: $context", 3);
                fsm_debug("  AFTER_SUBSTITUTION: $sv", 3);
                fsm_debug("  AST_OBJECT_AFTER: " . ref($expr_info->{ast}) . " @ $ast_ref", 3);
                fsm_debug("  SUBSTITUTED_BY: FSM::HDL::ASTFactorization->substitute_expressions_with_intermediate_signals()", 3);

                # Try to identify which intermediate signals are referenced
                my @referenced_intermediates = $ctx->{enable_graph_signal_support}->extract_intermediate_signals_from_ast($expr_info->{ast});
                if (@referenced_intermediates) {
                    fsm_debug("  REFERENCES_INTERMEDIATES: " . join(", ", @referenced_intermediates), 3);
                }
                fsm_debug("--- END SUBSTITUTED AST ---", 3);

                $shown++;
                last if $shown >= 10; # Show first 10 examples
            }
        }

        if ($shown == 0) {
            # informational note (debug trace of substitution accounting), not a problem.
            fsm_debug("no substituted expressions for substitution_count = $substitution_count", 3);
        }
    }

    # STEP 4: CRITICAL FIX - Update original AST expressions with substituted versions
    fsm_debug("\n*** STEP 4: UPDATING ORIGINAL AST EXPRESSIONS WITH SUBSTITUTED VERSIONS ***", 3);
    fsm_debug("*** AST OBJECT REPLACEMENT TRACKING - EVERY UPDATE WILL BE LOGGED ***", 3);

    # COUNT UNARY NEGATIONS BEFORE UPDATE
    fsm_debug("\n--- BEFORE AST UPDATE: Counting unary negations in original expressions ---", 3);
    $ctx->{enable_graph_factorization_support}->count_unary_negations_in_original_expressions();

    my $update_count = $ctx->{enable_graph_factorization_support}->update_original_asts_with_substituted_versions($factorizer);
    fsm_debug("*** ORIGINAL AST UPDATE COMPLETE: $update_count ASTs updated ***", 3);

    # COUNT UNARY NEGATIONS AFTER UPDATE
    fsm_debug("\n--- AFTER AST UPDATE: Counting unary negations in updated expressions ---", 3);
    $ctx->{enable_graph_factorization_support}->count_unary_negations_in_original_expressions();

    # STEP 5: FIXPOINT FACTORIZATION - Iterate on post-substitution expressions until convergence
    fsm_debug("\n*** STEP 5: FIXPOINT FACTORIZATION FOR POST-SUBSTITUTION EXPRESSIONS ***", 3);
    my $second_pass_result = $self->run_second_pass_factorization($factorizer);
    fsm_debug("*** FIXPOINT FACTORIZATION COMPLETE: " . scalar(keys %{$second_pass_result->{intermediate_signals}}) . " additional signals created across "
        . ($second_pass_result->{passes_run} // 0) . " pass(es); reason=$second_pass_result->{termination_reason} ***", 3);

    # Merge second-pass results into the main intermediate signals
    for my $signal_name (keys %{$second_pass_result->{intermediate_signals}}) {
        $intermediate_signals->{$signal_name} = $second_pass_result->{intermediate_signals}{$signal_name};
    }

    # STEP 6: Store factorizer for later lookup during HDL generation
    $ctx->{ast_factorizer} = $factorizer;

    fsm_debug("*** GENERIC AST FACTORIZATION COMPLETE ***", 3);
    fsm_debug("  Total expressions: $result->{total_expressions}", 3);
    fsm_debug("  Unique structures: $result->{unique_structures}", 3);
    fsm_debug("  Factorization candidates: $result->{factorization_candidates}", 3);
    fsm_debug("  Intermediate signals generated: " . scalar(keys %$intermediate_signals), 3);
    fsm_debug("  Substitution count: $substitution_count", 3);
    fsm_debug("  Original AST update count: $update_count", 3);
    fsm_debug("  Fixpoint passes run: " . ($second_pass_result->{passes_run} // 0), 3);
    fsm_debug("  Fixpoint termination reason: " . ($second_pass_result->{termination_reason} // 'unknown'), 3);

    return $result->{intermediate_signals};
}

=head2 run_second_pass_factorization

Delegate the iterative post-substitution factorization phase to the shared
C<FSM::HDL::Factorization::Fixpoint> owner while keeping the direct backend
pipeline boundary explicit.

=cut

sub run_second_pass_factorization ($self, $factorizer) {
    my $ctx = $self->{flattened_dt};
    fsm_debug("[GlobalFactorizationSupport.pm][run_second_pass_factorization()] Delegating iterative post-substitution factorization to FSM::HDL::Factorization::Fixpoint", 3);
    my $factorization_fixpoint = FSM::HDL::Factorization::Fixpoint->new(flattened_dt => $ctx);
    return $factorization_fixpoint->run_post_substitution_factorization(primary_factorizer => $factorizer);
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one global-factorization support owner bound to a prepared direct
backend context.

=head2 run_global_ast_factorization

Runs the live first-pass AST-factorization pipeline, including substitution,
original-AST refresh, fixpoint factorization, and factorizer persistence.

=head2 run_second_pass_factorization

Delegates the iterative post-substitution factorization phase to the shared
fixpoint owner.

=cut
