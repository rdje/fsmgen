package FSM::HDL::FlattenedDT::Backend::SystemVerilog;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Debug;
use FSM::HDL::Factorization::Fixpoint;
use List::Util qw(min);

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[FlattenedDT::Backend::SystemVerilog.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}
sub generate_intermediate_signals ($self, $fsm_module) {
    my $hdl = "";
    
    fsm_debug("\n*** PHASE: GENERATE INTERMEDIATE SIGNALS (FULLY AST-BASED) ***", 3);
    
    # STEP 1: Run global AST factorization on all WEN/EN expressions
    my $intermediate_signals = $self->run_global_ast_factorization();
    
    # STEP 2: Generate SystemVerilog declarations and assignments
    if (%$intermediate_signals) {
        $hdl .= "  // Intermediate signals for complex expressions\n";
        
        # Sort for deterministic output
        for my $signal_name (sort keys %$intermediate_signals) {
            my $signal_info = $intermediate_signals->{$signal_name};
            my $ast = $signal_info->{ast};
            my $width = $signal_info->{width} || 1;
            my $usage_count = $signal_info->{usage_count};
            
            fsm_debug("  Generating intermediate signal: $signal_name (width=$width, usage=$usage_count)", 3);
            
            # Generate wire declaration
            if ($width > 1) {
                $hdl .= "  wire [" . ($width - 1) . ":0] $signal_name;\n";
            } else {
                $hdl .= "  wire $signal_name;\n";
            }
            
            # Generate assign statement from AST
            my $systemverilog_expr = $ast->to_systemverilog();
            $hdl .= "  assign $signal_name = $systemverilog_expr;\n";
        }
    } else {
        fsm_debug("  No intermediate signals needed", 3);
    }
    
    fsm_debug("*** END PHASE: GENERATE INTERMEDIATE SIGNALS ***\n", 3);
    
    return $hdl;
}
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
        fsm_debug("*** WARNING: No logical operation counts available - this shouldn't happen! ***", 3);
        $ctx->{enable_graph}->count_binary_logical_operation_occurrences();
    }
    
    # Load the generic AST factorization system
    require FSM::HDL::ASTFactorization;
    
    # Initialize generic factorizer with enhanced debugging
    my $factorizer = FSM::HDL::ASTFactorization->new(
        min_usage_count => 2,
        debug => debug_enabled(),
        debug_level => 3  # Enable highest level of debug output
    );
    
    # STEP 1: Collect and add all AST expressions to factorizer
    fsm_debug("*** STEP 1: FEEDING ASTs TO FACTORIZER ***", 3);
    my $ast_count = $ctx->{enable_graph}->feed_asts_to_factorizer($factorizer);
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
        fsm_debug("*** WARNING: NO INTERMEDIATE SIGNALS GENERATED! ***", 3);
    }
    
    # STEP 3: CRITICAL - Substitute intermediate signals back into original expressions
    fsm_debug("\n*** STEP 3: AST SUBSTITUTION PHASE ***", 3);
    fsm_debug("*** AST REPLACEMENT TRACKING - EVERY SUBSTITUTION WILL BE LOGGED ***", 3);
    my $substitution_count = $factorizer->substitute_expressions_with_intermediate_signals($factorizer->{ast_expressions});
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
                my @referenced_intermediates = $ctx->{enable_graph}->extract_intermediate_signals_from_ast($expr_info->{ast});
                if (@referenced_intermediates) {
                    fsm_debug("  REFERENCES_INTERMEDIATES: " . join(", ", @referenced_intermediates), 3);
                }
                fsm_debug("--- END SUBSTITUTED AST ---", 3);
                
                $shown++;
                last if $shown >= 10; # Show first 10 examples
            }
        }
        
        if ($shown == 0) {
            fsm_debug("*** WARNING: No substituted expressions found despite substitution_count = $substitution_count ***", 3);
        }
    }
    
    # STEP 4: CRITICAL FIX - Update original AST expressions with substituted versions
    fsm_debug("\n*** STEP 4: UPDATING ORIGINAL AST EXPRESSIONS WITH SUBSTITUTED VERSIONS ***", 3);
    fsm_debug("*** AST OBJECT REPLACEMENT TRACKING - EVERY UPDATE WILL BE LOGGED ***", 3);
    
    # COUNT UNARY NEGATIONS BEFORE UPDATE
    fsm_debug("\n--- BEFORE AST UPDATE: Counting unary negations in original expressions ---", 3);
    $ctx->{enable_graph}->count_unary_negations_in_original_expressions();

    
    my $update_count = $ctx->{enable_graph}->update_original_asts_with_substituted_versions($factorizer);
    fsm_debug("*** ORIGINAL AST UPDATE COMPLETE: $update_count ASTs updated ***", 3);
    
    # COUNT UNARY NEGATIONS AFTER UPDATE  
    fsm_debug("\n--- AFTER AST UPDATE: Counting unary negations in updated expressions ---", 3);
    $ctx->{enable_graph}->count_unary_negations_in_original_expressions();
    
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
sub run_second_pass_factorization ($self, $factorizer) {
    my $ctx = $self->{flattened_dt};
    fsm_debug("[SystemVerilog.pm][run_second_pass_factorization()] Delegating iterative post-substitution factorization to FSM::HDL::Factorization::Fixpoint", 3);
    my $factorization_fixpoint = FSM::HDL::Factorization::Fixpoint->new(flattened_dt => $ctx);
    return $factorization_fixpoint->run_post_substitution_factorization(primary_factorizer => $factorizer);
}
sub get_substituted_ast_for_signal ($self, $signal_name, $signal_info) {
    my $ctx = $self->{flattened_dt};
    # Get the substituted AST for an intermediate signal from the factorizer results
    # This fixes the core issue where intermediate signal definitions use original ASTs
    # instead of substituted ASTs that reference other intermediate signals
    
    fsm_debug("GET_SUBSTITUTED_AST: Looking for substituted AST for signal '$signal_name'", 3);
    
    # CRITICAL FIX: Get the substituted AST directly from the factorizer's intermediate signals
    # After substitution, the factorizer stores the final substituted AST in its intermediate_signals structure
    if ($ctx->{ast_factorizer} && $ctx->{ast_factorizer}->{intermediate_signals}) {
        my $factorizer_signal_info = $ctx->{ast_factorizer}->{intermediate_signals}->{$signal_name};
        
        if ($factorizer_signal_info && $factorizer_signal_info->{ast}) {
            my $substituted_ast = $factorizer_signal_info->{ast};
            my $substituted_sv = eval { $ctx->{enable_graph}->ast_to_systemverilog($substituted_ast) } || "[NO SV REPRESENTATION]";
            
            fsm_debug("  FOUND substituted AST from factorizer: '$substituted_sv'", 3);
            return $substituted_ast;
        } else {
            fsm_debug("  Signal '$signal_name' not found in factorizer intermediate signals", 3);
        }
    } else {
        fsm_debug("  WARNING: No AST factorizer results available", 3);
    }
    
    # If no substituted version found, return nil to indicate original should be used
    return undef;
}

1;
