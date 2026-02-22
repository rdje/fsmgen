package FSM::Synthesis::EnableGraph;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';
use Scalar::Util qw(blessed);

use FSM::Debug;

sub new($class, %args) {
    Carp::confess "EnableGraph requires flattened_dt" unless $args{flattened_dt};
    return bless {
        flattened_dt => $args{flattened_dt},
    }, $class;
}
sub build_unified_assignment_analysis($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    fsm_debug("\n\n*** UNIFIED PHASE 1: BUILDING COMPLETE ASSIGNMENT ANALYSIS (AST WEB) ***", 3);
    
    # For each LHS signal name key, build complete analysis
    for my $lhs_name_key (keys %{$ctx->{all_lhs}}) {
        next unless $ctx->{lhs_assignments}->{$lhs_name_key};
        
        # Get AST node using mapping
        my $lhs_ast = $ctx->{lhs_ast_map}->{$lhs_name_key};
        
        # AST WEB: get signal name directly from AST node for debugging
        my $lhs_name = blessed($lhs_ast) && $lhs_ast->can('name') ? $lhs_ast->name() : $lhs_name_key;
        
        fsm_debug("\n=== ANALYZING LHS AST: $lhs_name ===", 3);
        fsm_debug("  Found " . scalar(@{$ctx->{lhs_assignments}->{$lhs_name_key}}) . " assignments", 3);
        
        # Initialize unified structure - signal_info intentionally omitted;
        # properties are queried directly from the LHS AST node when needed.
        $ctx->{assignment_analysis}->{$lhs_name_key} = {
            assignments => $ctx->{lhs_assignments}->{$lhs_name_key},
            rhs_groups => {},
            lhs_ast => $lhs_ast,
            multiplexer => {},
        };
        
        # Group assignments by RHS value and build enable structures
        $ctx->group_assignments_by_rhs($lhs_name_key);
        
        # Generate all enable signal names and expressions
        $ctx->generate_complete_enable_structure($lhs_name_key);
        
        # Build multiplexer configuration using direct AST queries
        $ctx->build_multiplexer_config($lhs_name_key);
        
        fsm_debug("  *** COMPLETED ANALYSIS FOR LHS AST: $lhs_name ***", 3);
    }
    
    fsm_debug("\n*** UNIFIED PHASE 1 COMPLETE (AST WEB) ***", 3);
}
sub group_assignments_by_rhs($self, $lhs) {
    my $ctx = $self->{flattened_dt};
    my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};
    
    fsm_debug("  [EnableGraph.pm][group_assignments_by_rhs()] Grouping assignments by RHS value:", 3);
    
    for my $assignment (@{$lhs_analysis->{assignments}}) {
        my $rhs = $assignment->{rhs};
        my $dt = $assignment->{dt};
        my $conditions = $assignment->{conditions} || 'NONE';
        my $conditions_ast = $assignment->{conditions_ast};
        
        # Initialize RHS group if not exists
        unless (exists $lhs_analysis->{rhs_groups}->{$rhs}) {
            $lhs_analysis->{rhs_groups}->{$rhs} = {
                assignments => [],
                dt_specific_enables => [],
                lhs_level_enable => undef,
                multiplexer_info => undef,
            };
        }
        
        # Add assignment to RHS group
        push @{$lhs_analysis->{rhs_groups}->{$rhs}->{assignments}}, $assignment;
        
        # Debug with proper handling of both old and new condition formats
        my $debug_condition = $conditions;
        if ($conditions_ast && blessed($conditions_ast) && $conditions_ast->can('to_systemverilog')) {
            $debug_condition = $conditions_ast->to_systemverilog();
        }
        fsm_debug("    [EnableGraph.pm] RHS '$rhs' from DT '$dt' with condition '$debug_condition'", 3);
    }
    
    my $rhs_count = scalar(keys %{$lhs_analysis->{rhs_groups}});
    fsm_debug("  [EnableGraph.pm] Grouped into $rhs_count unique RHS values", 3);
}

sub generate_complete_enable_structure($self, $lhs) {
    my $ctx = $self->{flattened_dt};
    my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};
    
    fsm_debug("  [EnableGraph.pm][generate_complete_enable_structure()] Generating complete enable structure:", 3);
    
    # Group assignments by DT first for DT-specific enables
    my %dt_assignments;
    for my $assignment (@{$lhs_analysis->{assignments}}) {
        my $dt_name = $assignment->{dt};
        my $rhs = $assignment->{rhs};
        
        $dt_assignments{$dt_name} //= {};
        $dt_assignments{$dt_name}{$rhs} //= [];
        push @{$dt_assignments{$dt_name}{$rhs}}, $assignment;
    }
    
    # Generate DT-specific enables for each DT/RHS combination
    for my $dt_name (sort keys %dt_assignments) {
        my $clean_dt_name = $dt_name;
        $clean_dt_name =~ s/^-//;  # Remove leading dash for standalone DTs
        
        # Get DT enable signal
        my $dt_enable;
        if ($ctx->{state_enables}->{$dt_name}) {
            $dt_enable = "${dt_name}_en";
        } elsif ($ctx->{dt_enables}->{$dt_name}) {
            $dt_enable = "${clean_dt_name}_en";
        } else {
            $dt_enable = "1'b1";
        }
        
        for my $rhs (sort keys %{$dt_assignments{$dt_name}}) {
            my $assignments = $dt_assignments{$dt_name}{$rhs};
            
            # Create OR of all conditions for this DT/LHS/RHS combination AS AST
            my @condition_asts;
            for my $assignment (@$assignments) {
                # The conditions are ASTs, not strings
                push @condition_asts, $assignment->{conditions_ast} if $assignment->{conditions_ast};
            }
            
            # Build OR tree of condition ASTs
            my $or_tree_of_conditions_ast;
            if (!@condition_asts) {
                # If there are no conditions, this enable depends only on the DT enable
                $or_tree_of_conditions_ast = FSM::AST::Utils::literal("1'b1");
            } elsif (@condition_asts == 1) {
                $or_tree_of_conditions_ast = $condition_asts[0];
            } else {
                $or_tree_of_conditions_ast = FSM::AST::Utils::or_tree(@condition_asts);
            }
            
            # Build complete enable expression as AST: dt_enable && conditions
            my $dt_enable_ast = FSM::AST::Utils::signal_ref($dt_enable);
            my $complete_enable_ast = FSM::AST::Utils::and_op($dt_enable_ast, $or_tree_of_conditions_ast);
            
            # Generate DT-specific enable signal name
            my $clean_rhs = $ctx->clean_signal_name($rhs);
            my $clean_lhs = $ctx->clean_signal_name($lhs);
            my $dt_enable_name = "${clean_dt_name}_${clean_lhs}_${clean_rhs}_en";
            
            # Store DT-specific enable info
            my $dt_enable_info = {
                dt => $dt_name,
                enable_name => $dt_enable_name,
                enable_ast => $complete_enable_ast,  # Store AST instead of string
                shared_signal => undef,              # Filled if sharing is detected
            };
            
            push @{$lhs_analysis->{rhs_groups}->{$rhs}->{dt_specific_enables}}, $dt_enable_info;
            
            # Debug with SystemVerilog conversion for display only
            my $debug_expr = $complete_enable_ast->to_systemverilog();
            fsm_debug("    [EnableGraph.pm] DT-specific enable: $dt_enable_name = $debug_expr", 3);
        }
    }
    
    # Generate LHS-level enables for each RHS
    for my $rhs (sort keys %{$lhs_analysis->{rhs_groups}}) {
        my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};
        
        # Create OR expression of all DT-specific enables for this RHS as AST
        my @dt_enable_asts;
        for my $dt_enable_info (@{$rhs_group->{dt_specific_enables}}) {
            push @dt_enable_asts, FSM::AST::Utils::signal_ref($dt_enable_info->{enable_name});
        }
        
        # Build OR tree AST for all DT-specific enables
        my $lhs_enable_ast;
        if (@dt_enable_asts == 1) {
            $lhs_enable_ast = $dt_enable_asts[0];
        } else {
            $lhs_enable_ast = FSM::AST::Utils::or_tree(@dt_enable_asts);
        }
        
        # Generate meaningful LHS-level enable name based on RHS
        my $lhs_enable_name = $ctx->generate_rhs_based_enable_name($lhs, $rhs);
        
        # Store LHS-level enable info with AST
        $rhs_group->{lhs_level_enable} = {
            name => $lhs_enable_name,
            ast => $lhs_enable_ast,
            rhs_value => $rhs,
        };
        
        # Debug with SystemVerilog conversion for display only
        my $debug_expr = blessed($lhs_enable_ast) && $lhs_enable_ast->can('to_systemverilog')
            ? $lhs_enable_ast->to_systemverilog()
            : 'UNAVAILABLE';
        fsm_debug("    [EnableGraph.pm] LHS-level enable: $lhs_enable_name = $debug_expr", 3);
    }
}
sub build_multiplexer_config($self, $lhs) {
    my $ctx = $self->{flattened_dt};
    my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};
    my $lhs_ast = $lhs_analysis->{lhs_ast};  # Get AST node for direct queries
    
    # AST WEB: Get signal name for debugging
    my $lhs_name = blessed($lhs_ast) && $lhs_ast->can('name') ? $lhs_ast->name() : 'UNKNOWN';
    
    # Collect all enable/value pairs for the multiplexer
    my @mux_enables = ();
    my $priority = 0;
    
    for my $rhs (sort keys %{$lhs_analysis->{rhs_groups}}) {
        my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};
        my $lhs_enable = $rhs_group->{lhs_level_enable};
        
        # Store multiplexer enable info
        $rhs_group->{multiplexer_info} = {
            enable_signal => $lhs_enable->{name},
            rhs_value => $rhs,
            priority => $priority++,
        };
        
        push @mux_enables, $rhs_group->{multiplexer_info};
    }
    
    # Determine multiplexer type using direct AST method calls
    my $is_register = $ctx->is_register($lhs_ast, $lhs_name);
    my $mux_type = $is_register ? 'flop' : 'comb';
    
    # Get default value using direct AST method calls
    my $default_value = $ctx->get_default_value_from_ast($lhs_ast);
    
    # Build complete multiplexer configuration
    $lhs_analysis->{multiplexer} = {
        type => $mux_type,
        enables => \@mux_enables,
        default_value => $default_value,
    };
    
    fsm_debug("  [EnableGraph.pm][build_multiplexer_config()] Multiplexer: type=$lhs_analysis->{multiplexer}->{type}, " . scalar(@mux_enables) . " enables", 3);
}

1;
