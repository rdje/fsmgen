package FSM::GlobalASTManager;

use strict;
use warnings;
use v5.20;
use feature 'signatures';
no warnings 'experimental::signatures';
use Scalar::Util qw(blessed);
use Digest::MD5 qw(md5_hex);
use FSM::Debug;

=head1 NAME

FSM::GlobalASTManager - Centralized Global AST Factorization and Naming

=head1 DESCRIPTION

This is the SINGLE AUTHORITY for all AST analysis and naming in the design.
It collects ALL ASTs from the entire design, performs global factorization 
analysis, and assigns consistent names to ASTs and sub-ASTs that occur multiple times.

Key principles:
- ONE name per unique AST structure (structural equality)
- Global analysis of ALL ASTs before any naming decisions
- Centralized authority - nothing else creates intermediate signal names
- Binary ops (A op B) and unary ops (op A) get factored if they occur multiple times
- Identical AST structures ALWAYS get the same name

=cut

sub new ($class, %args) {
    return bless {
        debug => $args{debug} // 0,
        
        # PHASE 1: Global AST Collection
        all_asts => [],                    # All ASTs from entire design
        ast_contexts => {},                # ast_id => [contexts where it appears]
        
        # PHASE 2: Structural Analysis
        ast_structural_map => {},          # structural_signature => canonical_ast
        ast_occurrence_count => {},        # structural_signature => count
        ast_occurrence_contexts => {},     # structural_signature => [contexts]
        
        # PHASE 3: Factorization Decisions  
        factored_asts => {},               # structural_signature => signal_name
        ast_name_map => {},                # ast_object_id => signal_name
        
        # PHASE 4: Sub-AST Analysis
        sub_ast_map => {},                 # sub_ast_signature => canonical_sub_ast
        sub_ast_occurrences => {},         # sub_ast_signature => count
        factored_sub_asts => {},           # sub_ast_signature => signal_name
        
        # Name generation
        name_counter => 0,
        used_names => {},                  # Prevent name collisions
        
        # Statistics
        stats => {
            total_asts_collected => 0,
            unique_ast_structures => 0,
            factored_top_level_asts => 0,
            factored_sub_asts => 0,
            total_intermediate_signals => 0
        }
    }, $class;
}

sub debug ($self, $msg) {
    fsm_debug("GAM-DEBUG: $msg", 3);
}

#========================================================================
# PHASE 1: GLOBAL AST COLLECTION
#========================================================================

sub collect_ast ($self, $ast, $context) {
    # Collect an AST from anywhere in the design for global analysis
    
    return unless ($ast && blessed($ast));
    
    push @{$self->{all_asts}}, $ast;
    
    my $ast_id = "$ast";  # Object reference as unique ID
    push @{$self->{ast_contexts}{$ast_id}}, $context;
    
    $self->{stats}{total_asts_collected}++;
    fsm_debug("GAM-DEBUG: COLLECT: AST from '$context' (total: $self->{stats}{total_asts_collected})", 3);
}

sub collect_all_asts_from_design ($self, $flattened_dt_generator) {
    # Collect ALL ASTs from the entire design before any analysis
    
    fsm_debug("GAM-DEBUG: \n*** PHASE 1: GLOBAL AST COLLECTION ***", 3);
    
    # Collect from LHS assignments (condition expressions)
    if ($flattened_dt_generator->{lhs_assignments}) {
        for my $lhs (keys %{$flattened_dt_generator->{lhs_assignments}}) {
            for my $assignment (@{$flattened_dt_generator->{lhs_assignments}{$lhs}}) {
                my $condition_expr = $assignment->{conditions};
                
                # Try to parse condition into AST
                if ($flattened_dt_generator->{expr_namer}) {
                    my $ast = eval { $flattened_dt_generator->{expr_namer}->parse_expression($condition_expr) };
                    if ($ast) {
                        $self->collect_ast($ast, "condition:$lhs:$assignment->{dt}");
                    }
                }
            }
        }
    }
    
    # Collect from unified assignment analysis
    if ($flattened_dt_generator->{assignment_analysis}) {
        for my $lhs (keys %{$flattened_dt_generator->{assignment_analysis}}) {
            my $lhs_analysis = $flattened_dt_generator->{assignment_analysis}{$lhs};
            
            for my $rhs (keys %{$lhs_analysis->{rhs_groups}}) {
                my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};
                
                # Collect from DT-specific enable expressions
                for my $dt_enable (@{$rhs_group->{dt_specific_enables} || []}) {
                    my $enable_expr = $dt_enable->{enable_expr};
                    
                    if ($flattened_dt_generator->{expr_namer}) {
                        my $ast = eval { $flattened_dt_generator->{expr_namer}->parse_expression($enable_expr) };
                        if ($ast) {
                            $self->collect_ast($ast, "dt_enable:$dt_enable->{enable_name}");
                        }
                    }
                }
                
                # Collect from LHS-level enable expressions
                if ($rhs_group->{lhs_level_enable}) {
                    my $lhs_enable_expr = $rhs_group->{lhs_level_enable}{expr};
                    
                    if ($flattened_dt_generator->{expr_namer}) {
                        my $ast = eval { $flattened_dt_generator->{expr_namer}->parse_expression($lhs_enable_expr) };
                        if ($ast) {
                            $self->collect_ast($ast, "lhs_enable:$rhs_group->{lhs_level_enable}{name}");
                        }
                    }
                }
            }
        }
    }
    
    fsm_debug("GAM-DEBUG: COLLECTION COMPLETE: Collected $self->{stats}{total_asts_collected} ASTs from design", 3);
}

#========================================================================
# PHASE 2: STRUCTURAL ANALYSIS
#========================================================================

sub perform_structural_analysis ($self) {
    # Analyze all collected ASTs to find structural duplicates
    
    fsm_debug("GAM-DEBUG: \n*** PHASE 2: STRUCTURAL ANALYSIS ***", 3);
    
    for my $ast (@{$self->{all_asts}}) {
        my $signature = $self->get_ast_structural_signature($ast);
        
        if (!exists $self->{ast_structural_map}{$signature}) {
            # First occurrence of this structure
            $self->{ast_structural_map}{$signature} = $ast;
            $self->{ast_occurrence_count}{$signature} = 1;
            $self->{ast_occurrence_contexts}{$signature} = [];
        } else {
            # Additional occurrence of this structure
            $self->{ast_occurrence_count}{$signature}++;
        }
        
        # Add context information
        my $ast_id = "$ast";
        if ($self->{ast_contexts}{$ast_id}) {
            push @{$self->{ast_occurrence_contexts}{$signature}}, @{$self->{ast_contexts}{$ast_id}};
        }
    }
    
    my $unique_structures = scalar(keys %{$self->{ast_structural_map}});
    $self->{stats}{unique_ast_structures} = $unique_structures;
    
    fsm_debug("GAM-DEBUG: STRUCTURAL ANALYSIS: Found $unique_structures unique AST structures", 3);
    
    # Report structures that occur multiple times (factorization candidates)
    for my $signature (keys %{$self->{ast_occurrence_count}}) {
        my $count = $self->{ast_occurrence_count}{$signature};
        if ($count > 1) {
            my $ast = $self->{ast_structural_map}{$signature};
            my $sv_str = eval { $ast->to_systemverilog() } || "unprintable";
            fsm_debug("GAM-DEBUG: FACTORIZATION CANDIDATE: '$sv_str' occurs $count times", 3);
        }
    }
}

sub get_ast_structural_signature ($self, $ast) {
    # Generate a structural signature for an AST that captures its shape and content
    # Identical structures will have identical signatures
    
    return "null" unless ($ast && blessed($ast));
    
    my $signature = $self->_build_structural_signature($ast);
    return md5_hex($signature);  # Hash for consistency and shorter keys
}

sub _build_structural_signature ($self, $node) {
    # Recursively build structural signature
    
    return "null" unless ($node && blessed($node));
    
    my $sig = ref($node) . ":";
    
    if ($node->isa('FSM::AST::BinaryOp')) {
        $sig .= "BinaryOp:" . $node->operator . ":" . 
                $self->_build_structural_signature($node->left) . ":" . 
                $self->_build_structural_signature($node->right);
    }
    elsif ($node->isa('FSM::AST::UnaryOp')) {
        $sig .= "UnaryOp:" . $node->operator . ":" . 
                $self->_build_structural_signature($node->operand);
    }
    elsif ($node->isa('FSM::AST::SignalRef')) {
        $sig .= "SignalRef:" . $node->name;
    }
    elsif ($node->isa('FSM::AST::Literal') || $node->isa('FSM::AST::LogicalConstant')) {
        $sig .= "Literal:" . $node->value;
    }
    else {
        # Unknown node type
        $sig .= "Unknown:" . ref($node);
    }
    
    return $sig;
}

#========================================================================
# PHASE 3: TOP-LEVEL AST FACTORIZATION
#========================================================================

sub perform_top_level_factorization ($self) {
    # Decide which top-level ASTs get factored and assign names
    
    fsm_debug("GAM-DEBUG: \n*** PHASE 3: TOP-LEVEL AST FACTORIZATION ***", 3);
    
    for my $signature (keys %{$self->{ast_occurrence_count}}) {
        my $count = $self->{ast_occurrence_count}{$signature};
        my $ast = $self->{ast_structural_map}{$signature};
        
        # Only factor ASTs that occur multiple times AND are complex enough
        if ($count > 1 && $self->should_factor_ast($ast)) {
            my $signal_name = $self->assign_name_to_ast($ast, $signature);
            $self->{factored_asts}{$signature} = $signal_name;
            
            # Map all AST objects with this signature to this name
            for my $design_ast (@{$self->{all_asts}}) {
                my $design_signature = $self->get_ast_structural_signature($design_ast);
                if ($design_signature eq $signature) {
                    my $ast_id = "$design_ast";
                    $self->{ast_name_map}{$ast_id} = $signal_name;
                }
            }
            
            $self->{stats}{factored_top_level_asts}++;
            
            my $sv_str = eval { $ast->to_systemverilog() } || "unprintable";
            fsm_debug("GAM-DEBUG: FACTORED TOP-LEVEL: '$sv_str' -> '$signal_name' ($count occurrences)", 3);
        }
    }
}

sub should_factor_ast ($self, $ast) {
    # Determine if an AST is complex enough to warrant factorization
    
    return 0 unless ($ast && blessed($ast));
    
    # Don't factor simple leaf nodes
    if ($ast->isa('FSM::AST::SignalRef') || 
        $ast->isa('FSM::AST::Literal') || 
        $ast->isa('FSM::AST::LogicalConstant')) {
        return 0;
    }
    
    # Factor binary operations (A op B) - these are prime candidates
    if ($ast->isa('FSM::AST::BinaryOp')) {
        return 1;
    }
    
    # Factor unary operations (op A) if they're not trivial
    if ($ast->isa('FSM::AST::UnaryOp')) {
        # Factor negations and other unary ops
        return 1;
    }
    
    # Factor other complex expressions
    return 1;
}

#========================================================================
# PHASE 4: SUB-AST FACTORIZATION
#========================================================================

sub perform_sub_ast_factorization ($self) {
    # Find sub-ASTs that occur multiple times across different top-level ASTs
    
    fsm_debug("GAM-DEBUG: \n*** PHASE 4: SUB-AST FACTORIZATION ***", 3);
    
    # Collect all sub-ASTs from all top-level ASTs
    my %sub_ast_occurrences;
    
    for my $ast (@{$self->{all_asts}}) {
        my $sub_asts = $self->extract_all_sub_asts($ast);
        
        for my $sub_ast (@$sub_asts) {
            my $sub_signature = $self->get_ast_structural_signature($sub_ast);
            
            if (!exists $sub_ast_occurrences{$sub_signature}) {
                $sub_ast_occurrences{$sub_signature} = {
                    canonical_ast => $sub_ast,
                    count => 1,
                    contexts => []
                };
            } else {
                $sub_ast_occurrences{$sub_signature}{count}++;
            }
            
            # Track context
            my $ast_id = "$ast";
            if ($self->{ast_contexts}{$ast_id}) {
                push @{$sub_ast_occurrences{$sub_signature}{contexts}}, @{$self->{ast_contexts}{$ast_id}};
            }
        }
    }
    
    # Factor sub-ASTs that occur multiple times
    for my $sub_signature (keys %sub_ast_occurrences) {
        my $info = $sub_ast_occurrences{$sub_signature};
        my $count = $info->{count};
        my $sub_ast = $info->{canonical_ast};
        
        if ($count > 1 && $self->should_factor_ast($sub_ast)) {
            # Skip if this sub-AST is already factored as a top-level AST
            next if exists $self->{factored_asts}{$sub_signature};
            
            my $signal_name = $self->assign_name_to_ast($sub_ast, $sub_signature, "sub");
            $self->{factored_sub_asts}{$sub_signature} = $signal_name;
            
            $self->{stats}{factored_sub_asts}++;
            
            my $sv_str = eval { $sub_ast->to_systemverilog() } || "unprintable";
            fsm_debug("GAM-DEBUG: FACTORED SUB-AST: '$sv_str' -> '$signal_name' ($count occurrences)", 3);
        }
    }
}

sub extract_all_sub_asts ($self, $ast) {
    # Extract all sub-ASTs from an AST (recursive traversal)
    
    my @sub_asts;
    return \@sub_asts unless ($ast && blessed($ast));
    
    if ($ast->isa('FSM::AST::BinaryOp')) {
        # Add operands as sub-ASTs
        if ($ast->left && blessed($ast->left)) {
            push @sub_asts, $ast->left;
            push @sub_asts, @{$self->extract_all_sub_asts($ast->left)};
        }
        if ($ast->right && blessed($ast->right)) {
            push @sub_asts, $ast->right;
            push @sub_asts, @{$self->extract_all_sub_asts($ast->right)};
        }
    }
    elsif ($ast->isa('FSM::AST::UnaryOp')) {
        if ($ast->operand && blessed($ast->operand)) {
            push @sub_asts, $ast->operand;
            push @sub_asts, @{$self->extract_all_sub_asts($ast->operand)};
        }
    }
    
    return \@sub_asts;
}

#========================================================================
# NAME ASSIGNMENT
#========================================================================

sub assign_name_to_ast ($self, $ast, $signature, $prefix = "") {
    # Assign a meaningful and unique name to an AST
    
    my $base_name = $self->generate_ast_based_name($ast, $prefix);
    my $unique_name = $self->ensure_unique_name($base_name);
    
    # Record that this name is used
    $self->{used_names}{$unique_name} = {
        ast => $ast,
        signature => $signature,
        created_at => scalar(localtime)
    };
    
    $self->{stats}{total_intermediate_signals}++;
    
    return $unique_name;
}

sub generate_ast_based_name ($self, $ast, $prefix = "") {
    # Generate a meaningful name based on AST structure
    
    return "unknown" unless ($ast && blessed($ast));
    
    my $name = $prefix ? "${prefix}_" : "";
    
    if ($ast->isa('FSM::AST::BinaryOp')) {
        my $op = $ast->operator;
        my $left_name = $self->get_simple_ast_name($ast->left);
        my $right_name = $self->get_simple_ast_name($ast->right);
        
        my $op_name = $self->operator_to_name($op);
        $name .= "${left_name}_${op_name}_${right_name}";
    }
    elsif ($ast->isa('FSM::AST::UnaryOp')) {
        my $op = $ast->operator;
        my $operand_name = $self->get_simple_ast_name($ast->operand);
        
        my $op_name = $self->operator_to_name($op);
        $name .= "${op_name}_${operand_name}";
    }
    elsif ($ast->isa('FSM::AST::SignalRef')) {
        $name .= $ast->name;
    }
    else {
        $name .= "expr";
    }
    
    return $self->clean_signal_name($name);
}

sub get_simple_ast_name ($self, $ast) {
    # Get a simple name for an AST node (for use in compound names)
    
    return "null" unless ($ast && blessed($ast));
    
    if ($ast->isa('FSM::AST::SignalRef')) {
        return $ast->name;
    }
    elsif ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::AST::LogicalConstant')) {
        my $val = $ast->value;
        $val =~ s/[^a-zA-Z0-9]/_/g;
        return "const_${val}";
    }
    else {
        return "expr";
    }
}

sub operator_to_name ($self, $op) {
    # Convert operators to name components
    my %op_map = (
        '&&' => 'and',
        '||' => 'or',
        '&'  => 'and',
        '|'  => 'or',
        '!'  => 'not',
        '~'  => 'not',
        '==' => 'eq',
        '!=' => 'neq',
        '<'  => 'lt',
        '>'  => 'gt',
        '<=' => 'le',
        '>=' => 'ge',
        '+'  => 'plus',
        '-'  => 'minus',
        '*'  => 'mul',
        '/'  => 'div',
        '^'  => 'xor'
    );
    
    return $op_map{$op} || "op";
}

sub clean_signal_name ($self, $name) {
    # Clean signal names for Verilog compatibility
    $name = lc($name);
    $name =~ s/[^a-zA-Z0-9_]/_/g;
    $name =~ s/__+/_/g;
    $name =~ s/^_+//;
    $name =~ s/_+$//;
    $name =~ s/^(\d)/_$1/;
    return $name || "unnamed";
}

sub ensure_unique_name ($self, $base_name) {
    # Ensure name uniqueness
    my $name = $base_name;
    my $counter = 1;
    
    while (exists $self->{used_names}{$name}) {
        $name = "${base_name}_${counter}";
        $counter++;
    }
    
    return $name;
}

#========================================================================
# PUBLIC INTERFACE
#========================================================================

sub run_global_factorization ($self, $flattened_dt_generator) {
    # Run the complete global factorization process
    
    fsm_debug("GAM-DEBUG: \n=== STARTING GLOBAL AST FACTORIZATION ===", 3);
    
    # Phase 1: Collect all ASTs from the design
    $self->collect_all_asts_from_design($flattened_dt_generator);
    
    # Phase 2: Analyze structural duplicates
    $self->perform_structural_analysis();
    
    # Phase 3: Factor top-level ASTs
    $self->perform_top_level_factorization();
    
    # Phase 4: Factor sub-ASTs
    $self->perform_sub_ast_factorization();
    
    fsm_debug("GAM-DEBUG: === GLOBAL AST FACTORIZATION COMPLETE ===\n", 3);
    $self->print_statistics();
    
    return $self->get_all_factored_signals();
}

sub get_name_for_ast ($self, $ast) {
    # Get the assigned name for an AST (if factored)
    
    return undef unless ($ast && blessed($ast));
    
    my $ast_id = "$ast";
    return $self->{ast_name_map}{$ast_id};
}

sub get_name_for_ast_structure ($self, $ast) {
    # Get the assigned name for an AST based on its structure
    
    return undef unless ($ast && blessed($ast));
    
    my $signature = $self->get_ast_structural_signature($ast);
    
    # Check top-level factorization first
    if (exists $self->{factored_asts}{$signature}) {
        return $self->{factored_asts}{$signature};
    }
    
    # Check sub-AST factorization
    if (exists $self->{factored_sub_asts}{$signature}) {
        return $self->{factored_sub_asts}{$signature};
    }
    
    return undef;
}

sub get_all_factored_signals ($self) {
    # Return all factored signals for HDL generation
    
    my %all_signals;
    
    # Add top-level factored ASTs
    for my $signature (keys %{$self->{factored_asts}}) {
        my $signal_name = $self->{factored_asts}{$signature};
        my $ast = $self->{ast_structural_map}{$signature};
        my $expr = eval { $ast->to_systemverilog() } || "unprintable";
        
        $all_signals{$signal_name} = {
            expr => $expr,
            width => 1,  # Boolean expressions
            source => 'global_factorization',
            usage_count => $self->{ast_occurrence_count}{$signature}
        };
    }
    
    # Add sub-AST factored signals
    for my $signature (keys %{$self->{factored_sub_asts}}) {
        my $signal_name = $self->{factored_sub_asts}{$signature};
        # Find the canonical AST for this signature
        my $ast = undef;
        for my $design_ast (@{$self->{all_asts}}) {
            my $sub_asts = $self->extract_all_sub_asts($design_ast);
            for my $sub_ast (@$sub_asts) {
                if ($self->get_ast_structural_signature($sub_ast) eq $signature) {
                    $ast = $sub_ast;
                    last;
                }
            }
            last if $ast;
        }
        
        if ($ast) {
            my $expr = eval { $ast->to_systemverilog() } || "unprintable";
            $all_signals{$signal_name} = {
                expr => $expr,
                width => 1,
                source => 'sub_ast_factorization',
                usage_count => 2  # At least 2 if factored
            };
        }
    }
    
    return \%all_signals;
}

sub print_statistics ($self) {
    # Print detailed statistics
    
    my $stats = $self->{stats};
    fsm_debug("", 3);
    fsm_debug("=== GLOBAL AST MANAGER STATISTICS ===", 3);
    fsm_debug("Total ASTs collected: $stats->{total_asts_collected}", 3);
    fsm_debug("Unique AST structures: $stats->{unique_ast_structures}", 3);
    fsm_debug("Factored top-level ASTs: $stats->{factored_top_level_asts}", 3);
    fsm_debug("Factored sub-ASTs: $stats->{factored_sub_asts}", 3);
    fsm_debug("Total intermediate signals: $stats->{total_intermediate_signals}", 3);
    fsm_debug("=====================================", 3);
}

1;
