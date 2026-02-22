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
sub generate_unified_wen_en_signals($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my $hdl = "  // Unified WEN/EN Signal Generation from Phase 1 Analysis\n";
    
    fsm_debug("\n\n*** UNIFIED PHASE 2: GENERATING WEN/EN SIGNALS FROM ANALYSIS ***", 3);
    
    # Generate DT-specific enables first
    $hdl .= $self->generate_dt_enables_from_analysis();
    
    # Generate LHS-level enables
    $hdl .= $self->generate_lhs_enables_from_analysis();
    
    fsm_debug("*** UNIFIED PHASE 2 COMPLETE ***", 3);
    
    return $hdl;
}
sub generate_dt_enables_from_analysis($self) {
    my $ctx = $self->{flattened_dt};
    
    fsm_debug("GENERATE_DT_ENABLES: [ENTRY] Starting DT-specific enable generation from analysis", 3);
    my $hdl = "  // DT-Specific Enable Signals from Unified Analysis\n";
    
    # Track all intermediate signals referenced in enable expressions
    $ctx->{referenced_intermediate_signals} //= {};
    fsm_debug("GENERATE_DT_ENABLES: [INIT] Initialized referenced_intermediate_signals tracking", 3);
    
    # REORGANIZED: Group by DT first, then show all LHS signals within each DT
    # Build a mapping from DT -> LHS -> RHS -> enable_info
    my %dt_to_lhs_enables;
    fsm_debug("GENERATE_DT_ENABLES: [INIT] Starting to build DT->LHS->RHS mapping", 3);
    
for my $lhs (sort keys %{$ctx->{assignment_analysis}}) {
        fsm_debug("GENERATE_DT_ENABLES: [LHS_PROCESSING] Processing LHS '$lhs'", 3);
        my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};
        my $rhs_count = scalar(keys %{$lhs_analysis->{rhs_groups}});
        fsm_debug("GENERATE_DT_ENABLES: [LHS_RHS_COUNT] LHS '$lhs' has $rhs_count RHS groups", 3);
        
        for my $rhs (sort keys %{$lhs_analysis->{rhs_groups}}) {
            fsm_debug("GENERATE_DT_ENABLES: [RHS_PROCESSING] Processing LHS '$lhs' RHS '$rhs'", 3);
            my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};
            my $dt_enable_count = scalar(@{$rhs_group->{dt_specific_enables}});
            fsm_debug("GENERATE_DT_ENABLES: [DT_ENABLE_COUNT] RHS '$rhs' has $dt_enable_count DT-specific enables", 3);
            
            for my $dt_enable_info (@{$rhs_group->{dt_specific_enables}}) {
                my $enable_name = $dt_enable_info->{enable_name};
                my $enable_ast = $dt_enable_info->{enable_ast};
                my $dt_name = $dt_enable_info->{dt};
                
                fsm_debug("GENERATE_DT_ENABLES: [DT_ENABLE_INFO] Processing DT enable:", 3);
                fsm_debug("  Enable name: $enable_name", 3);
                fsm_debug("  DT name: $dt_name", 3);
                fsm_debug("  Enable AST type: " . (blessed($enable_ast) ? ref($enable_ast) : 'NOT_BLESSED'));
                
                # Track intermediate signals in this AST
                fsm_debug("GENERATE_DT_ENABLES: [TRACK_INTERMEDIATE] Tracking intermediate signals for '$enable_name'", 3);
                $ctx->track_ast_intermediate_signals($enable_ast);
                
                # Group by DT first
                $dt_to_lhs_enables{$dt_name} //= {};
                $dt_to_lhs_enables{$dt_name}{$lhs} //= [];
                fsm_debug("GENERATE_DT_ENABLES: [GROUPING] Grouping enable '$enable_name' under DT '$dt_name' LHS '$lhs'", 3);
                
                push @{$dt_to_lhs_enables{$dt_name}{$lhs}}, {
                    enable_name => $enable_name,
                    enable_ast => $enable_ast,
                    rhs => $rhs
                };
            }
        }
    }
    
    # Generate output grouped by DT
    for my $dt_name (sort keys %dt_to_lhs_enables) {
        my $clean_dt_name = $dt_name;
        $clean_dt_name =~ s/^-//;  # Remove leading dash for standalone DTs
        
        $hdl .= "\n\n  // === DT: $dt_name ===\n";
        
        # Show all LHS signals within this DT
        for my $lhs (sort keys %{$dt_to_lhs_enables{$dt_name}}) {
            $hdl .= "  // $lhs\n";
            
            for my $enable_info (@{$dt_to_lhs_enables{$dt_name}{$lhs}}) {
                my $enable_name = $enable_info->{enable_name};
                my $enable_ast = $enable_info->{enable_ast};
                my $rhs = $enable_info->{rhs};
                
                # Convert AST to SystemVerilog for output (without outer parentheses)
                my $enable_expr = $ctx->ast_to_systemverilog($enable_ast);
                
                $hdl .= "  assign $enable_name = $enable_expr;  // $lhs <- $rhs\n";
                
                fsm_debug("  Generated DT-specific enable: $enable_name = $enable_expr", 3);
            }
        }
    }
    
    return $hdl;
}
sub generate_lhs_enables_from_analysis($self) {
    my $ctx = $self->{flattened_dt};
    my $hdl = "\n  // LHS-Level Enable Signals from Unified Analysis\n";
    
    # Process each LHS from the unified analysis
    for my $lhs (sort keys %{$ctx->{assignment_analysis}}) {
        my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};
        
        $hdl .= "\n  // LHS-level enables for: $lhs\n";
        
        # Generate LHS-level enables for each RHS
        for my $rhs (sort keys %{$lhs_analysis->{rhs_groups}}) {
            my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};
            my $lhs_enable = $rhs_group->{lhs_level_enable};
            
            if ($lhs_enable) {
                my $enable_name = $lhs_enable->{name};
                my $enable_ast = $lhs_enable->{ast};
                
                # Track intermediate signals in this AST
                $ctx->track_ast_intermediate_signals($enable_ast);
                
                # Convert AST to SystemVerilog for output (without outer parentheses)
                my $enable_expr = $ctx->ast_to_systemverilog($enable_ast);
                
                $hdl .= "  assign $enable_name = $enable_expr;\n";
                
                fsm_debug("  Generated LHS-level enable: $enable_name = $enable_expr", 3);
            }
        }
    }
    
    return $hdl;
}
sub generate_signal_assignments($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my $hdl = "\n  // Unified Multiplexer Logic from Phase 1 Analysis\n";
    
    fsm_debug("\n\n*** UNIFIED PHASE 3: GENERATING MULTIPLEXERS FROM ANALYSIS ***", 3);
    
    # Generate multiplexers for all LHS signals from unified analysis
    for my $lhs (sort keys %{$ctx->{assignment_analysis}}) {
        my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};
        my $multiplexer = $lhs_analysis->{multiplexer};
        my $assignment_type = $self->get_signal_assignment_type($lhs, $lhs_analysis);
        
        $hdl .= "\n  // Unified Multiplexer for LHS: $lhs\n";
        
        if ($assignment_type eq 'pulse_delayed') {
            $hdl .= $self->generate_unified_pulse_delay_logic($lhs, $lhs_analysis);
        } elsif ($multiplexer->{type} eq 'flop') {
            $hdl .= $self->generate_unified_flop_mux($lhs, $lhs_analysis);
        } else {
            $hdl .= $self->generate_unified_comb_mux($lhs, $lhs_analysis);
        }
        
        fsm_debug("  Generated unified multiplexer for $lhs (type: $multiplexer->{type}, assignment_type: $assignment_type)", 3);
    }
    
    fsm_debug("*** UNIFIED PHASE 3 COMPLETE ***", 3);
    
    return $hdl;
}
sub generate_unified_pulse_delay_logic($self, $lhs, $lhs_analysis) {
    my $ctx = $self->{flattened_dt};
    my $lhs_ast = $lhs_analysis->{lhs_ast};
    my $lhs_name = blessed($lhs_ast) && $lhs_ast->can('name') ? $lhs_ast->name() : $lhs;
    my $delay_cycles = $self->get_pulse_delay_cycles_for_lhs($lhs, $lhs_analysis);
    my $active_level = $self->get_pulse_active_level_for_lhs($lhs, $lhs_analysis);
    my $rest_level = $active_level ? "1'b0" : "1'b1";
    my $pulse_level = $active_level ? "1'b1" : "1'b0";
    my $width = $ctx->get_lhs_width_from_analysis($lhs_analysis);
    
    if ($width != 1) {
        die "[EnableGraph.pm][generate_unified_pulse_delay_logic()] Delayed pulse target '$lhs_name' must be 1-bit, got width '$width'";
    }
    
    my @request_signals = map { $_->{enable_signal} } @{$lhs_analysis->{multiplexer}->{enables} || []};
    my $request_expr = @request_signals ? join(' | ', @request_signals) : "1'b0";
    
    my $hdl = "  // Delayed pulse logic for: $lhs_name (<$delay_cycles, exact Q+$delay_cycles)\n";
    
    if ($delay_cycles == 0) {
        $hdl .= "  always_ff @(posedge clk or negedge rstn) begin\n";
        $hdl .= "    if (!rstn) begin\n";
        $hdl .= "      $lhs_name <= $rest_level;\n";
        $hdl .= "    end else begin\n";
        $hdl .= "      $lhs_name <= ($request_expr) ? $pulse_level : $rest_level;\n";
        $hdl .= "    end\n";
        $hdl .= "  end\n";
        return $hdl;
    }
    
    my $pipe_name = "${lhs_name}_pulse_delay_pipe";
    my $pipe_tap = $delay_cycles == 1 ? $pipe_name : "${pipe_name}[" . ($delay_cycles - 1) . "]";
    my $shift_rhs = $delay_cycles == 1
        ? $request_expr
        : "{${pipe_name}[" . ($delay_cycles - 2) . ":0], $request_expr}";
    my $pipe_reset = $delay_cycles == 1
        ? "1'b0"
        : '{' . $delay_cycles . "{1'b0}}";
    
    $hdl .= "  always_ff @(posedge clk or negedge rstn) begin\n";
    $hdl .= "    if (!rstn) begin\n";
    $hdl .= "      $lhs_name <= $rest_level;\n";
    $hdl .= "      $pipe_name <= $pipe_reset;\n";
    $hdl .= "    end else begin\n";
    $hdl .= "      $lhs_name <= $rest_level;\n";
    $hdl .= "      if ($pipe_tap) begin\n";
    $hdl .= "        $lhs_name <= $pulse_level;\n";
    $hdl .= "      end\n";
    $hdl .= "      $pipe_name <= $shift_rhs;\n";
    $hdl .= "    end\n";
    $hdl .= "  end\n";
    
    return $hdl;
}
sub get_pulse_delay_cycles_for_lhs($self, $lhs, $lhs_analysis) {
    my %delay_values;
    for my $assignment (@{$lhs_analysis->{assignments} || []}) {
        my $op = $assignment->{operator} // '';
        if ($op =~ /^<(\d+)$/) {
            $delay_values{$1} = 1;
            next;
        }
        my $intent = $assignment->{assignment_intent};
        if (ref($intent) eq 'HASH' && defined($intent->{pulse_delay_cycles})) {
            $delay_values{$intent->{pulse_delay_cycles}} = 1;
        }
    }
    my @delays = sort { $a <=> $b } keys %delay_values;
    if (!@delays) {
        die "[EnableGraph.pm][get_pulse_delay_cycles_for_lhs()] Missing pulse delay metadata for LHS '$lhs'";
    }
    if (@delays > 1) {
        die "[EnableGraph.pm][get_pulse_delay_cycles_for_lhs()] Multiple pulse delays for LHS '$lhs' are unsupported: " . join(', ', @delays);
    }
    return $delays[0];
}
sub get_pulse_active_level_for_lhs($self, $lhs, $lhs_analysis) {
    my %active_levels;
    for my $assignment (@{$lhs_analysis->{assignments} || []}) {
        my $intent = $assignment->{assignment_intent};
        if (ref($intent) eq 'HASH' && defined($intent->{pulse_active_level})) {
            $active_levels{int($intent->{pulse_active_level} ? 1 : 0)} = 1;
            next;
        }
        my $rhs = $assignment->{rhs};
        my $normalized = $self->normalize_rhs_logic_level($rhs);
        if (defined $normalized) {
            $active_levels{$normalized} = 1;
        }
    }
    my @levels = sort { $a <=> $b } keys %active_levels;
    if (!@levels) {
        die "[EnableGraph.pm][get_pulse_active_level_for_lhs()] Missing pulse active level metadata for LHS '$lhs'";
    }
    if (@levels > 1) {
        die "[EnableGraph.pm][get_pulse_active_level_for_lhs()] Conflicting pulse active levels for LHS '$lhs': " . join(', ', @levels);
    }
    return $levels[0];
}
sub normalize_rhs_logic_level($self, $rhs) {
    return undef unless defined $rhs;
    return 0 if $rhs =~ /^(?:0|1'b0|1'd0|1'h0)$/i;
    return 1 if $rhs =~ /^(?:1|1'b1|1'd1|1'h1)$/i;
    return undef;
}
sub generate_unified_flop_mux($self, $lhs, $lhs_analysis) {
    my $ctx = $self->{flattened_dt};
    my $multiplexer = $lhs_analysis->{multiplexer};
    my $lhs_ast = $lhs_analysis->{lhs_ast};  # Get the AST node for direct queries
    
    # AST WEB: Get signal name for debugging and HDL generation
    my $lhs_name = blessed($lhs_ast) && $lhs_ast->can('name') ? $lhs_ast->name() : 'UNKNOWN';
    
    # Determine the assignment type by examining the operators used
    my $assignment_type = $self->get_signal_assignment_type($lhs, $lhs_analysis);
    
    my $hdl = "  // Unified flop with mux for: $lhs_name ($assignment_type assignment)\n";
    
    if ($assignment_type eq 'register_out' || $assignment_type eq 'register_out_dual') {
        # <- / <-= assignment: A is a register, A_next is the mux output
        my $emit_next_output = ($assignment_type eq 'register_out_dual') ? 1 : 0;
        my $next_output_name = "next_${lhs_name}";
        
        # Generate the combinational multiplexer logic
        $hdl .= "  always_comb begin\n";
        $hdl .= "    ${lhs_name}_next = $multiplexer->{default_value};  // Default value\n";
        
        # Use enables from unified analysis - these match exactly with generated signals
        for my $enable_info (@{$multiplexer->{enables}}) {
            my $enable_signal = $enable_info->{enable_signal};
            my $rhs_value = $enable_info->{rhs_value};
            
            $hdl .= "    if ($enable_signal) begin\n";
            $hdl .= "      ${lhs_name}_next = $rhs_value;\n";
            $hdl .= "    end\n";
            
            fsm_debug("    Unified flop mux (<-): $enable_signal -> $rhs_value", 3);
        }
        
        if ($emit_next_output) {
            $hdl .= "    $next_output_name = ${lhs_name}_next;\n";
            fsm_debug("    Unified flop mux (<-=): exposing '$next_output_name'", 3);
        }
        
        $hdl .= "  end\n";
        
        # AST WEB: Get reset value using direct AST method calls
        my $reset_value = $self->get_reset_value_from_ast($lhs_ast);

        
        # Generate the flip-flop
        $hdl .= "  always_ff @(posedge clk or negedge rstn) begin\n";
        $hdl .= "    if (!rstn) begin\n";
        $hdl .= "      $lhs_name <= $reset_value;\n";
        $hdl .= "    end else begin\n";
        $hdl .= "      $lhs_name <= ${lhs_name}_next;\n";
        $hdl .= "    end\n";
        $hdl .= "  end\n";
        
    } elsif ($assignment_type eq 'register_in' || $assignment_type eq 'register_in_dual') {
        # <= / <=+ assignment: A is the mux output, A_q is the flop output that provides feedback
        my $emit_q_output = ($assignment_type eq 'register_in_dual') ? 1 : 0;
        my $q_output_name = "${lhs_name}_r";
        
        # Generate the combinational multiplexer logic
        $hdl .= "  always_comb begin\n";
        $hdl .= "    $lhs_name = ${lhs_name}_q;  // Default value is feedback from flop output\n";
        if ($emit_q_output) {
            $hdl .= "    $q_output_name = ${lhs_name}_q;\n";
        }
        
        # Use enables from unified analysis - these match exactly with generated signals
        for my $enable_info (@{$multiplexer->{enables}}) {
            my $enable_signal = $enable_info->{enable_signal};
            my $rhs_value = $enable_info->{rhs_value};
            
            $hdl .= "    if ($enable_signal) begin\n";
            $hdl .= "      $lhs_name = $rhs_value;\n";
            $hdl .= "    end\n";
            
            fsm_debug("    Unified flop mux (<=): $enable_signal -> $rhs_value", 3);
        }
        
        $hdl .= "  end\n";
        
        # AST WEB: Get reset value using direct AST method calls
        my $reset_value = $self->get_reset_value_from_ast($lhs_ast);
        
        # Generate the flip-flop (output is A_q, input is A)
        $hdl .= "  always_ff @(posedge clk or negedge rstn) begin\n";
        $hdl .= "    if (!rstn) begin\n";
        $hdl .= "      ${lhs_name}_q <= $reset_value;\n";
        $hdl .= "    end else begin\n";
        $hdl .= "      ${lhs_name}_q <= $lhs_name;\n";
        $hdl .= "    end\n";
        $hdl .= "  end\n";
    } else {
        die "[EnableGraph.pm][generate_unified_flop_mux()] Unsupported flop assignment_type '$assignment_type' for LHS '$lhs_name'";
    }
    
    return $hdl;
}
sub generate_unified_comb_mux($self, $lhs, $lhs_analysis) {
    my $multiplexer = $lhs_analysis->{multiplexer};
    
    my $hdl = "  // Unified combinational mux for: $lhs\n";
    
    $hdl .= "  always_comb begin\n";
    # For combinational logic, default to 1'b0 to avoid feedback loops
    # CRITICAL FIX: Never use signal name as default for combinational multiplexers
    my $safe_default = "1'b0";  # Safe default for combinational logic
    $hdl .= "    $lhs = $safe_default;  // Default value\n";
    
    # Use enables from unified analysis - these match exactly with generated signals
    for my $enable_info (@{$multiplexer->{enables}}) {
        my $enable_signal = $enable_info->{enable_signal};
        my $rhs_value = $enable_info->{rhs_value};
        
        $hdl .= "    if ($enable_signal) begin\n";
        $hdl .= "      $lhs = $rhs_value;\n";
        $hdl .= "    end\n";
        
        fsm_debug("    Unified comb mux: $enable_signal -> $rhs_value", 3);
    }
    
    $hdl .= "  end\n";
    
    return $hdl;
}
sub signal_uses_register_assignment($self, $lhs, $lhs_analysis) {
    # Determine if a signal uses <- assignments (register assignments)
    # Returns: boolean (1 if uses <-, 0 otherwise)
    my $assignments = $lhs_analysis->{assignments};
    
    for my $assignment (@$assignments) {
        my $operator = $assignment->{operator} || '=';
        
        if ($operator eq '<-' || $operator eq '<=' || $operator eq '<-=' || $operator eq '<=+' || $operator =~ /^<\d+$/) {
            return 1;  # Uses register assignment
        }
    }
    
    return 0;  # Does not use register assignment
}
sub get_signal_assignment_type($self, $lhs, $lhs_analysis) {
    # Determine the assignment type for a signal by examining the operators used
    # Returns:
    #   'register_out'      for <- assignments
    #   'register_in'       for <= assignments
    #   'register_out_dual' for <-= assignments (rm)
    #   'register_in_dual'  for <=+ assignments (mr)
    #   'pulse_delayed'     for <N assignments (pN, exact Q+N pulse)
    #   'mux_out'           for = assignments
    
    # Add error handling for missing or empty assignments
    my $assignments = $lhs_analysis->{assignments};
    unless ($assignments && @$assignments) {
        fsm_debug("WARNING: No assignments found for LHS '$lhs', defaulting to 'mux_out'", 3);
        return 'mux_out';  # Default to combinational assignment
    }
    
    my $has_register_assignment = 0;       # <-
    my $has_flop_assignment = 0;           # <=
    my $has_register_dual_assignment = 0;  # <-=
    my $has_flop_dual_assignment = 0;      # <=+
    my $has_comb_assignment = 0;           # =
    my $has_pulse_assignment = 0;          # <N
    my %pulse_delays;
    
    for my $assignment (@$assignments) {
        my $operator = $assignment->{operator};
        if (!defined($operator) || $operator eq '') {
            die "[EnableGraph.pm][get_signal_assignment_type()] Missing operator in assignment analysis for LHS '$lhs'";
        }
        
        if ($operator eq '<-') {
            $has_register_assignment = 1;
        } elsif ($operator eq '<=') {
            $has_flop_assignment = 1;
        } elsif ($operator eq '<-=') {
            $has_register_dual_assignment = 1;
        } elsif ($operator eq '<=+') {
            $has_flop_dual_assignment = 1;
        } elsif ($operator eq '=') {
            $has_comb_assignment = 1;
        } elsif ($operator =~ /^<(\d+)$/) {
            $has_pulse_assignment = 1;
            $pulse_delays{$1} = 1;
        } else {
            die "[EnableGraph.pm][get_signal_assignment_type()] Unsupported operator '$operator' in assignment analysis for LHS '$lhs'";
        }
    }
    
    my $sequential_family_count = 0;
    $sequential_family_count++ if $has_register_assignment;
    $sequential_family_count++ if $has_flop_assignment;
    $sequential_family_count++ if $has_register_dual_assignment;
    $sequential_family_count++ if $has_flop_dual_assignment;
    $sequential_family_count++ if $has_pulse_assignment;
    
    if ($has_comb_assignment && $sequential_family_count > 0) {
        die "[EnableGraph.pm][get_signal_assignment_type()] Mixed combinational '=' and sequential operators for LHS '$lhs' is unsupported";
    }
    
    if (keys(%pulse_delays) > 1) {
        die "[EnableGraph.pm][get_signal_assignment_type()] Multiple pulse delays for LHS '$lhs' are unsupported: " . join(', ', sort keys %pulse_delays);
    }
    
    if ($has_pulse_assignment && ($has_register_assignment || $has_flop_assignment || $has_register_dual_assignment || $has_flop_dual_assignment)) {
        die "[EnableGraph.pm][get_signal_assignment_type()] Mixed pulse-delayed and non-pulse sequential operators for LHS '$lhs' is unsupported";
    }
    
    if ($has_register_dual_assignment) {
        if ($has_flop_assignment || $has_flop_dual_assignment) {
            die "[EnableGraph.pm][get_signal_assignment_type()] Mixed '<-=' with '<='/'<=+' for LHS '$lhs' is unsupported";
        }
        return 'register_out_dual';
    }
    if ($has_flop_dual_assignment) {
        if ($has_register_assignment || $has_register_dual_assignment) {
            die "[EnableGraph.pm][get_signal_assignment_type()] Mixed '<=+' with '<-'/'<-=' for LHS '$lhs' is unsupported";
        }
        return 'register_in_dual';
    }
    if ($has_pulse_assignment) {
        return 'pulse_delayed';
    }
    if ($has_register_assignment) {
        return 'register_out';
    }
    if ($has_flop_assignment) {
        return 'register_in';
    }
    return 'mux_out';
}
sub get_driven_signals($self) {
    # Return hash of signals that are driven by the FSM (should be outputs)
    # This is determined by checking if they appear as LHS in assignments
    my $ctx = $self->{flattened_dt};
    my %driven_signals;
    
    # Check all recorded LHS assignments
    for my $lhs (keys %{$ctx->{all_lhs}}) {
        $driven_signals{$lhs} = 1;
        fsm_debug("[EnableGraph.pm][get_driven_signals()] DRIVEN_SIGNALS: '$lhs' is driven by FSM logic", 3);
    }
    
    # Include auxiliary outputs exposed by sequential dual families:
    #   rm (<-=): next_<lhs>
    #   mr (<=+): <lhs>_r
    for my $lhs (keys %{$ctx->{assignment_analysis} || {}}) {
        my $lhs_analysis = $ctx->{assignment_analysis}{$lhs};
        next unless $lhs_analysis;
        my $assignment_type = $self->get_signal_assignment_type($lhs, $lhs_analysis);
        
        if ($assignment_type eq 'register_out_dual') {
            my $next_name = "next_$lhs";
            $driven_signals{$next_name} = 1;
            fsm_debug("[EnableGraph.pm][get_driven_signals()] DRIVEN_SIGNALS: '$next_name' is driven by rm auxiliary output logic", 3);
        } elsif ($assignment_type eq 'register_in_dual') {
            my $q_name = "${lhs}_r";
            $driven_signals{$q_name} = 1;
            fsm_debug("[EnableGraph.pm][get_driven_signals()] DRIVEN_SIGNALS: '$q_name' is driven by mr auxiliary output logic", 3);
        }
    }
    
    return %driven_signals;
}
sub get_reset_value($self, $lhs) {
    # Provide appropriate reset values for different signals
    # Use semantic information and explicit conventions, NOT name-based heuristics
    my $ctx = $self->{flattened_dt};
    
    fsm_debug("GET_RESET_VALUE: Determining reset value for LHS '$lhs'", 3);
    
    # Check if this is the FSM state variable (semantic check)
    if ($lhs eq 'next_state') {
        # For the FSM state variable, get the reset state from the FSM module
        my $reset_state = $self->get_fsm_reset_state();
        fsm_debug("GET_RESET_VALUE: State variable '$lhs' -> reset to '$reset_state'", 3);
        return $reset_state;
    }
    
    # Check if this LHS has explicit reset information from the FSM specification
    my $explicit_reset = $self->get_explicit_reset_value($lhs);
    if (defined $explicit_reset) {
        fsm_debug("GET_RESET_VALUE: Explicit reset for '$lhs' -> '$explicit_reset'", 3);
        return $explicit_reset;
    }
    
    # Check signal width to determine appropriate default reset value
    my $signal_info = $self->get_signal_info($lhs);
    if ($signal_info && $signal_info->{width}) {
        my $width = $signal_info->{width};
        if ($width > 1) {
            my $reset_val = sprintf("%d'h%s", $width, "0" x int(($width + 3) / 4));
            fsm_debug("GET_RESET_VALUE: Multi-bit signal '$lhs' ($width bits) -> '$reset_val'", 3);
            return $reset_val;
        }
    }
    
    # Default: single-bit signals reset to 0
    fsm_debug("GET_RESET_VALUE: Default single-bit reset for '$lhs' -> '1'b0'", 3);
    return "1'b0";
}
sub get_default_value($self, $lhs) {
    # For flop assignments (A <-), the default should be the current register value (feedback)
    # This is different from reset values, which are used for initialization
    
    # For state variable, use proper feedback
    if ($lhs eq 'next_state') {
        return "current_state";
    }
    
    # For all other register assignments, use feedback from the register itself
    # This ensures proper flop behavior where the register maintains its value
    # unless explicitly overridden by an enable condition
    return $lhs;  # Use the signal itself as feedback (current register value)
}
sub get_fsm_reset_state($self) {
    # Get the reset state for the FSM from the FSM module
    # The reset state is conventionally the first state in the state list
    my $ctx = $self->{flattened_dt};
    
    # If we have access to the FSM module, get the first regular state
    if ($ctx->{fsm_module}) {
        my @regular_states = grep { $_->name !~ /^-/ } @{$ctx->{fsm_module}->states};
        if (@regular_states) {
            my $reset_state = uc($regular_states[0]->name);
            fsm_debug("FSM_RESET_STATE: Using first state as reset: '$reset_state'", 3);
            return $reset_state;
        }
    }
    
    # If no FSM module available or no states, default to IDLE
    fsm_debug("FSM_RESET_STATE: Defaulting to IDLE", 3);
    return "IDLE";
}
sub get_explicit_reset_value($self, $lhs) {
    # Check if this LHS has explicit reset information from the FSM specification
    # This could come from signal attributes, FSM metadata, or explicit configuration
    my $ctx = $self->{flattened_dt};
    
    fsm_debug("EXPLICIT_RESET: Checking for explicit reset value for '$lhs'", 3);
    
    # Check if we have explicit reset values configured
    if ($ctx->{explicit_reset_values} && $ctx->{explicit_reset_values}{$lhs}) {
        my $reset_val = $ctx->{explicit_reset_values}{$lhs};
        fsm_debug("EXPLICIT_RESET: Found configured reset for '$lhs' -> '$reset_val'", 3);
        return $reset_val;
    }
    
    # Check signal attributes if available through FSM module
    if ($ctx->{fsm_module} && $ctx->{fsm_module}->signals) {
        my $signals = $ctx->{fsm_module}->signals;
        if ($signals->{$lhs}) {
            my $signal = $signals->{$lhs};
            
            # Check for reset_value attribute
            if ($signal->can('attributes') && $signal->attributes && $signal->attributes->{reset_value}) {
                my $reset_val = $signal->attributes->{reset_value};
                fsm_debug("EXPLICIT_RESET: Found signal attribute reset for '$lhs' -> '$reset_val'", 3);
                return $reset_val;
            }
            
            # Check for reset_value method
            if ($signal->can('reset_value')) {
                my $reset_val = $signal->reset_value;
                if (defined $reset_val) {
                    fsm_debug("EXPLICIT_RESET: Found signal method reset for '$lhs' -> '$reset_val'", 3);
                    return $reset_val;
                }
            }
        }
    }
    
    # No explicit reset value found
    fsm_debug("EXPLICIT_RESET: No explicit reset value found for '$lhs'", 3);
    return undef;
}
sub get_signal_info($self, $lhs) {
    # Get signal information from the FSM module
    # Returns: { width => N, ... } or undef if not found
    my $ctx = $self->{flattened_dt};
    
    fsm_debug("SIGNAL_INFO: Getting info for '$lhs'", 3);
    
    # Check if we have FSM module with signals
    if ($ctx->{fsm_module} && $ctx->{fsm_module}->signals) {
        my $signals = $ctx->{fsm_module}->signals;
        if ($signals->{$lhs}) {
            my $signal = $signals->{$lhs};
            
            my $signal_info = {};
            
            # Get width if available
            if ($signal->can('width')) {
                my $width = $signal->width;
                if ($width && $width > 0) {
                    $signal_info->{width} = $width;
                    fsm_debug("SIGNAL_INFO: Found width for '$lhs' -> $width", 3);
                } else {
                    fsm_debug("SIGNAL_INFO: Width method returned invalid value for '$lhs'", 3);
                }
            } else {
                fsm_debug("SIGNAL_INFO: No width method for '$lhs'", 3);
            }
            
            # Get other attributes if needed
            # ... (can add more signal attributes here in the future)
            
            return $signal_info if %$signal_info;
        } else {
            fsm_debug("SIGNAL_INFO: Signal '$lhs' not found in FSM signals", 3);
        }
    } else {
        fsm_debug("SIGNAL_INFO: No FSM module or signals available", 3);
    }
    
    return undef;
}
sub get_reset_value_from_ast($self, $lhs_ast) {
    # AST WEB: Get reset value using direct AST queries
    my $ctx = $self->{flattened_dt};
    
    # Use proper signal name extraction that handles different AST types
    my $lhs_name = $ctx->extract_signal_name_from_ast($lhs_ast);
    unless (defined $lhs_name) {
        fsm_debug("WARNING: Could not extract signal name from AST, using fallback", 3);
        $lhs_name = 'unknown_signal';
    }
    fsm_debug("GET_RESET_VALUE_FROM_AST: Getting reset value for '$lhs_name'", 3);
    
    # Try AST method first
    if ($lhs_ast->can('reset_value')) {
        my $reset_val = $lhs_ast->reset_value();
        if (defined $reset_val) {
            fsm_debug("  AST reset_value: '$reset_val'", 3);
            return $reset_val;
        }
    }
    
    # Fallback to name-based logic
    fsm_debug("  No AST reset value, using fallback", 3);
    return $self->get_reset_value($lhs_name);
}
sub get_default_value_from_ast($self, $lhs_ast) {
    # AST WEB: Get default value using direct AST queries
    # DEBUG: Check what type of object we have
    my $ctx = $self->{flattened_dt};
    
    fsm_debug("DEBUG: lhs_ast object type: " . ref($lhs_ast), 3);
    fsm_debug("DEBUG: lhs_ast blessed: " . (blessed($lhs_ast) || 'NOT BLESSED'), 3);
    if (blessed($lhs_ast)) {
        fsm_debug("DEBUG: lhs_ast can name: " . ($lhs_ast->can('name') ? 'YES' : 'NO'), 3);
        my @methods = qw(name signal type operands);
        for my $method (@methods) {
            fsm_debug("DEBUG: lhs_ast can $method: " . ($lhs_ast->can($method) ? 'YES' : 'NO'), 3);
        }
    }
    
    # Use proper signal name extraction that handles different AST types
    my $lhs_name = $ctx->extract_signal_name_from_ast($lhs_ast);
    unless (defined $lhs_name) {
        fsm_debug("WARNING: Could not extract signal name from AST, using fallback", 3);
        $lhs_name = 'unknown_signal';
    }
    fsm_debug("GET_DEFAULT_VALUE_FROM_AST: Getting default value for '$lhs_name'", 3);
    
    # Try AST methods first
    if ($lhs_ast->can('default_value')) {
        my $default_val = $lhs_ast->default_value();
        if (defined $default_val) {
            fsm_debug("  AST default_value: '$default_val'", 3);
            return $default_val;
        }
    }
    
    # Fallback to reset_value if available
    if ($lhs_ast->can('reset_value')) {
        my $reset_val = $lhs_ast->reset_value();
        if (defined $reset_val) {
            fsm_debug("  Using AST reset_value as default: '$reset_val'", 3);
            return $reset_val;
        }
    }
    
    # Fallback to name-based logic
    fsm_debug("  No AST default value, using fallback", 3);
    return $self->get_default_value($lhs_name);
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
            my $clean_rhs = $self->clean_signal_name($rhs);
            my $clean_lhs = $self->clean_signal_name($lhs);
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
        my $lhs_enable_name = $self->generate_rhs_based_enable_name($lhs, $rhs);
        
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
    my $default_value = $self->get_default_value_from_ast($lhs_ast);
    
    # Build complete multiplexer configuration
    $lhs_analysis->{multiplexer} = {
        type => $mux_type,
        enables => \@mux_enables,
        default_value => $default_value,
    };
    
    fsm_debug("  [EnableGraph.pm][build_multiplexer_config()] Multiplexer: type=$lhs_analysis->{multiplexer}->{type}, " . scalar(@mux_enables) . " enables", 3);
}
sub clean_signal_name($self, $name) {
    # Clean signal names for use in Verilog identifiers
    $name = lc($name);             # Convert to lowercase for consistent WEN/EN naming
    $name =~ s/[^a-zA-Z0-9_]/_/g;  # Replace non-alphanumeric with underscore
    $name =~ s/__+/_/g;            # Replace multiple consecutive underscores with single underscore
    $name =~ s/^_+//;              # Remove leading underscores
    $name =~ s/_+$//;              # Remove trailing underscores
    
    # Handle special cases for numeric RHS values BEFORE digit prefixing
    # Don't prefix simple numeric values with underscores to avoid double underscores
    if ($name eq '0') {
        return '0';
    } elsif ($name eq '1') {
        return '1';
    }
    
    # Only prefix with underscore if starts with digit (for complex numeric identifiers)
    $name =~ s/^(\d)/_$1/;         # Prefix with underscore if starts with digit
    
    return $name;
}
sub generate_rhs_based_enable_name($self, $lhs, $rhs) {
    my $ctx = $self->{flattened_dt};
    
    # Generate meaningful enable signal names based on RHS expression type
    # Following the naming convention: <LHS>_<RHS_description>_en
    my $clean_lhs = $self->clean_signal_name($lhs);
    my $rhs_suffix;
    
    # Handle different RHS expression types
    if ($rhs =~ /^\d+$/) {
        # Simple numeric values: 0, 1, 42
        $rhs_suffix = $rhs;
        
    } elsif ($rhs =~ /^\d+'[bdhBDH]([0-9a-fA-F_]+)$/) {
        # Sized literals: 8'h00, 16'b1010, etc.
        my $value_part = $1;
        $rhs_suffix = $rhs;
        $rhs_suffix =~ s/'/_/g;  # Replace ' with _ : 8'h00 -> 8_h00
        $rhs_suffix = $self->clean_signal_name($rhs_suffix);
        
    } elsif ($rhs =~ /^([a-zA-Z_][a-zA-Z0-9_]*)\[(\d+):(\d+)\]$/) {
        # Bit slice: signal[7:0], data[15:8]
        my ($signal, $high, $low) = ($1, $2, $3);
        $rhs_suffix = "${signal}_${high}_${low}";
        
    } elsif ($rhs =~ /^([a-zA-Z_][a-zA-Z0-9_]*)\[(\d+)\]$/) {
        # Single bit index: signal[5], enable[0]
        my ($signal, $index) = ($1, $2);
        $rhs_suffix = "${signal}_${index}";
        
    } elsif ($rhs =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/) {
        # Simple identifier: signal_name, apb_wrn, const_8b0
        $rhs_suffix = $rhs;
        
    } else {
        # Complex expression: use expression namer to create meaningful name
        my $expr_name = $ctx->{expr_namer}->parse_and_name_expression($rhs);
        # Remove common prefixes/suffixes to keep name concise
        $expr_name =~ s/_expr\d*$//;  # Remove _expr suffix
        $expr_name =~ s/^expr_//;     # Remove expr_ prefix
        $rhs_suffix = $expr_name || "complex";
    }
    
    # Clean the suffix and combine with LHS
    $rhs_suffix = $self->clean_signal_name($rhs_suffix);
    return "${clean_lhs}_${rhs_suffix}_en";
}

1;
