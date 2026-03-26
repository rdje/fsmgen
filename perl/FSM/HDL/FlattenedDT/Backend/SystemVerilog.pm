package FSM::HDL::FlattenedDT::Backend::SystemVerilog;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Debug;
use FSM::HDL::Factorization::Fixpoint;
use Data::Dumper;
use Scalar::Util qw(blessed);
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
sub generate_consolidated_intermediate_signals ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my $signal_support = $ctx->{backend_sv_intermediate_support};
    # Initialize intermediate signals storage
    $ctx->{intermediate_signals} = {};

    # CONSOLIDATED APPROACH: Generate intermediate signals from AST factorization AND pre-scan
    # This eliminates the duplicate signal generation issue
    
    fsm_debug("\n*** CONSOLIDATED INTERMEDIATE SIGNAL GENERATION ***", 3);
    fsm_debug("CONSOL_INTER_SIG: [ENTRY] FSM module: " . ($fsm_module ? $fsm_module->name : 'undefined'), 3);
    fsm_debug("CONSOL_INTER_SIG: [ENTRY] Current intermediate signals count: " . scalar(keys %{$ctx->{intermediate_signals} || {}}), 3);
    fsm_debug("CONSOL_INTER_SIG: [ENTRY] Current referenced signals count: " . scalar(keys %{$ctx->{referenced_intermediate_signals} || {}}), 3);
    
    # SIGNAL_TRACE: Complete dump of ALL signals at FSM module level (pipeline entry)
    if ($fsm_module && $fsm_module->signals) {
        my $fsm_signals = $fsm_module->signals;
        my $total_signals = scalar(keys %$fsm_signals);
        fsm_debug("SIGNAL_TRACE: FSM module has $total_signals total signals at PIPELINE_ENTRY", 3);
        
        # Categorize signals for better analysis
        my (@intermediate_signals, @regular_signals, @or_pattern_signals, @signals_with_driving_ast);
        
        for my $sig_name (sort keys %$fsm_signals) {
            my $signal = $fsm_signals->{$sig_name};
            
            # Check signal properties
            my $has_driving_ast = ($signal->can('driving_ast') && $signal->driving_ast) ? 1 : 0;
            my $is_intermediate = 0;
            
            # Try multiple ways to check for intermediate status
            if ($signal->can('get_attribute')) {
                $is_intermediate = $signal->get_attribute('is_intermediate') || 0;
            } elsif ($signal->can('attributes') && $signal->attributes) {
                $is_intermediate = $signal->attributes->{is_intermediate} || 0;
            }
            
            # Get AST/expression information
            my $ast_info = "NONE";
            my $expression_info = "NONE";
            my $ast_dump = "NO_AST";
            
            if ($has_driving_ast) {
                my $driving_ast = $signal->driving_ast;
                $ast_info = ref($driving_ast) || "UNKNOWN_TYPE";
                
                # Try to get SystemVerilog representation
                if ($driving_ast && $driving_ast->can('to_systemverilog')) {
                    $expression_info = eval { $driving_ast->to_systemverilog() } || "[AST_TO_SV_FAILED]";
                } else {
                    $expression_info = "[NO_TO_SYSTEMVERILOG_METHOD]";
                }
                
                # Get Data::Dumper representation of the AST
                $ast_dump = Data::Dumper->new([$driving_ast], ["${sig_name}_AST"])->Indent(2)->Sortkeys(1)->Dump();
            }
            
            # Categorize the signal
            if ($is_intermediate) {
                push @intermediate_signals, $sig_name;
            }
            if ($has_driving_ast) {
                push @signals_with_driving_ast, $sig_name;
            }
            if ($sig_name =~ /^or_\d+_\d+$/) {
                push @or_pattern_signals, $sig_name;
            } else {
                push @regular_signals, $sig_name;
            }
            
            # Detailed trace for each signal with complete AST dump
            fsm_debug("\n=== SIGNAL ANALYSIS: [$sig_name] ===", 3);
            fsm_debug("  Signal object type: " . ref($signal), 3);
            fsm_debug("  Has driving_ast: " . ($has_driving_ast ? "YES" : "NO"), 3);
            fsm_debug("  Is intermediate: " . ($is_intermediate ? "YES" : "NO"), 3);
            fsm_debug("  AST type: $ast_info", 3);
            fsm_debug("  SystemVerilog expression: $expression_info", 3);
            
            # Full AST dump using Data::Dumper
            fsm_debug("  AST DUMP:", 3);
            my @dump_lines = split(/\n/, $ast_dump);
            for my $line (@dump_lines) {
                fsm_debug("    $line", 3);
            }
            fsm_debug("=== END SIGNAL: [$sig_name] ===\n", 3);
        }
        
        # Summary statistics
        fsm_debug("\n*** SIGNAL_TRACE SUMMARY ***", 3);
        fsm_debug("  - Total signals: $total_signals", 3);
        fsm_debug("  - Intermediate signals: " . scalar(@intermediate_signals) . " (" . join(", ", @intermediate_signals) . ")", 3);
        fsm_debug("  - Signals with driving_ast: " . scalar(@signals_with_driving_ast) . " (" . join(", ", @signals_with_driving_ast) . ")", 3);
        fsm_debug("  - or_*_* pattern signals: " . scalar(@or_pattern_signals) . " (" . join(", ", @or_pattern_signals) . ")", 3);
        fsm_debug("  - Regular signals: " . scalar(@regular_signals), 3);
        fsm_debug("*** END SIGNAL_TRACE SUMMARY ***\n", 3);
    } else {
        fsm_debug("SIGNAL_TRACE: WARNING - No FSM module or signals available at pipeline entry!", 3);
    }
    
    my $hdl = "";
    
    # Step 1: Run AST factorization to identify common sub-expressions
    my $ast_intermediate_signals = $self->run_global_ast_factorization();
    
    # Step 2: Merge with pre-scan results to get comprehensive list
    my %all_intermediate_signals;
    
    # Add signals from AST factorization
    if ($ast_intermediate_signals && %$ast_intermediate_signals) {
        for my $signal_name (keys %$ast_intermediate_signals) {
            $all_intermediate_signals{$signal_name} = {
                source => 'ast_factorization',
                %{$ast_intermediate_signals->{$signal_name}}
            };
        }
    }
    
    # Add signals from pre-scan (referenced by WEN/EN but not yet declared)
    if ($ctx->{referenced_intermediate_signals}) {
        for my $signal_name (keys %{$ctx->{referenced_intermediate_signals}}) {
            # Only add if not already in AST factorization results
            unless (exists $all_intermediate_signals{$signal_name}) {
                my $referenced_signal_info = $ctx->{referenced_intermediate_signals}->{$signal_name} || {};
                my $runtime_ast = $signal_support->resolve_intermediate_signal_runtime_ast($signal_name, $referenced_signal_info);
                my $expression = (!$runtime_ast || !blessed($runtime_ast))
                    ? $ctx->{enable_graph}->get_intermediate_signal_expression($signal_name)
                    : undef;
                if (($runtime_ast && blessed($runtime_ast)) || $expression) {
                    $all_intermediate_signals{$signal_name} = {
                        source => 'prescan_reference',
                        %$referenced_signal_info,
                        ($runtime_ast && blessed($runtime_ast) ? (ast => $runtime_ast, runtime_ast => $runtime_ast) : ()),
                        (defined($expression) && $expression ne '' ? (expression => $expression) : ()),
                        usage_count => 1
                    };
                }
            }
        }
    }
    
    # Step 2.5: Add intermediate signals from FSMGenFull parsing (CRITICAL FIX)
    # These are signals created during FSMGen parsing with driving_ast already set
    if ($fsm_module && $fsm_module->can('signals') && $fsm_module->signals) {
        fsm_debug("CONSOL_INTER_SIG: [FSMGEN_SIGNALS] Scanning FSM module for intermediate signals from parsing", 3);
        my $fsm_signals = $fsm_module->signals;
        my $fsmgen_intermediate_count = 0;
        
        fsm_debug("  FSMGEN_SIGNALS: FSM module has " . scalar(keys %$fsm_signals) . " total signals", 3);
        
        for my $signal_name (keys %$fsm_signals) {
            my $signal = $fsm_signals->{$signal_name};
            
            # Debug every signal to understand the structure
            fsm_debug("  FSMGEN_SIGNAL_SCAN: '$signal_name' -> " . ref($signal), 3);
            
            # Check if this signal has driving_ast (more flexible check)
            if ($signal && $signal->can('driving_ast') && $signal->driving_ast) {
                fsm_debug("    HAS_DRIVING_AST: '$signal_name' has driving AST", 3);
                
                # Check for intermediate marker with more flexible attribute checking
                my $is_intermediate = 0;
                
                # ENHANCED DEBUG: Show what we're working with
                fsm_debug("      SIGNAL_DEBUG: Processing signal '$signal_name'", 3);
                fsm_debug("        Signal object type: " . ref($signal), 3);
                fsm_debug("        Signal blessed: " . (blessed($signal) ? 'YES' : 'NO'), 3);
                
                # Method 1: Try get_attribute method
                if ($signal->can('get_attribute')) {
                    $is_intermediate = $signal->get_attribute('is_intermediate');
                    fsm_debug("      METHOD1: get_attribute('is_intermediate') = " . (defined($is_intermediate) ? $is_intermediate : 'undef'), 3);
                }
                
                # Method 2: Try attributes hash
                if (!$is_intermediate && $signal->can('attributes') && $signal->attributes) {
                    $is_intermediate = $signal->attributes->{is_intermediate};
                    fsm_debug("      METHOD2: attributes->{is_intermediate} = " . (defined($is_intermediate) ? $is_intermediate : 'undef'), 3);
                }
                
                # Method 3: Try direct hash access (for FSM::CoreAST::Signal)
                if (!$is_intermediate && ref($signal) eq 'HASH' && exists($signal->{is_intermediate})) {
                    $is_intermediate = $signal->{is_intermediate};
                    fsm_debug("      METHOD3: signal->{is_intermediate} = " . (defined($is_intermediate) ? $is_intermediate : 'undef'), 3);
                }
                
                # Method 4: Try direct property access (for object-based signals)
                if (!$is_intermediate && blessed($signal) && $signal->can('is_intermediate')) {
                    $is_intermediate = eval { $signal->is_intermediate } || 0;
                    fsm_debug("      METHOD4: signal->is_intermediate() = " . (defined($is_intermediate) ? $is_intermediate : 'undef'), 3);
                }
                
                # Method 5: Direct dereferencing with proper error handling
                if (!$is_intermediate && blessed($signal)) {
                    # Use eval to safely access the hash representation
                    my $signal_hash = eval { \%{$signal} };
                    if ($signal_hash && exists $signal_hash->{is_intermediate}) {
                        $is_intermediate = $signal_hash->{is_intermediate};
                        fsm_debug("      METHOD5: direct hash deref to is_intermediate = " . (defined($is_intermediate) ? $is_intermediate : 'undef'), 3);
                    }
                }
                
                # Method 6: Check FSM::CoreAST::Signal internal structure
                if (!$is_intermediate && blessed($signal) && $signal->isa('FSM::CoreAST::Signal')) {
                    # FSM::CoreAST::Signal may store attributes in constructor arguments
                    # Check all keys in the signal object for is_intermediate
                    for my $key (keys %$signal) {
                        if ($key eq 'is_intermediate' && defined($signal->{$key})) {
                            $is_intermediate = $signal->{$key};
                            fsm_debug("      METHOD6: Found is_intermediate as direct key '$key' = $is_intermediate", 3);
                            last;
                        }
                    }
                }
                
                fsm_debug("    IS_INTERMEDIATE_CHECK: '$signal_name' intermediate status: " . ($is_intermediate || 'undefined'), 3);
                
                # If it has driving_ast and is marked intermediate - no arbitrary name pattern matching
                if ($is_intermediate) {
                    # CRITICAL FIX: Even if already added from other sources (pre-scan), 
                    # FSMGenFull intermediate signals should ALWAYS be processed because 
                    # they have the actual AST and expression information needed for declaration
                    
                    # Declare driving_ast once at the outer scope to avoid scoping issues
                    my $driving_ast = $signal->driving_ast;
                    
                    if (exists $all_intermediate_signals{$signal_name}) {
                        fsm_debug("  FSMGEN_INTERMEDIATE: Signal '$signal_name' already exists, but UPDATING with FSMGenFull AST data", 3);
                        # Update the existing entry with proper AST information from FSMGenFull
                        $all_intermediate_signals{$signal_name} = {
                            source => 'fsmgen_parsing',
                            ast => $driving_ast,
                            width => ($signal->can('width') ? $signal->width : undef) || 1,
                            usage_count => 1,  # Conservative estimate
                            driving_ast => $driving_ast  # Store both ast and driving_ast for compatibility
                        };
                        $fsmgen_intermediate_count++;
                        
                        fsm_debug("  FSMGEN_INTERMEDIATE: UPDATED signal '$signal_name' with driving AST: " . ref($driving_ast), 3);
                        my $updated_ast_sv = eval { $driving_ast->to_systemverilog() };
                        $updated_ast_sv = '[AST ERROR]' if !defined($updated_ast_sv) || $updated_ast_sv eq '' || $@;
                        fsm_debug("    AST SystemVerilog: $updated_ast_sv", 3);
                    } else {
                        # This is a new FSMGenFull intermediate signal with proper driving AST
                        fsm_debug("  FSMGEN_INTERMEDIATE: Found NEW signal '$signal_name' with driving AST: " . ref($driving_ast), 3);
                        my $new_ast_sv = eval { $driving_ast->to_systemverilog() };
                        $new_ast_sv = '[AST ERROR]' if !defined($new_ast_sv) || $new_ast_sv eq '' || $@;
                        fsm_debug("    AST SystemVerilog: $new_ast_sv", 3);
                        
                        $all_intermediate_signals{$signal_name} = {
                            source => 'fsmgen_parsing',
                            ast => $driving_ast,
                            width => ($signal->can('width') ? $signal->width : undef) || 1,
                            usage_count => 1,  # Conservative estimate
                            driving_ast => $driving_ast  # Store both ast and driving_ast for compatibility
                        };
                        $fsmgen_intermediate_count++;
                    }
                } else {
                    fsm_debug("    NOT_INTERMEDIATE: Signal '$signal_name' has driving AST but is not marked as intermediate", 3);
                }
            } else {
                # Debug why this signal doesn't qualify
                if (!$signal) {
                    fsm_debug("    SKIP: '$signal_name' - signal object is null", 3);
                } elsif (!$signal->can('driving_ast')) {
                    fsm_debug("    SKIP: '$signal_name' - signal has no driving_ast method", 3);
                } elsif (!$signal->driving_ast) {
                    fsm_debug("    SKIP: '$signal_name' - signal has no driving_ast set", 3);
                }
            }
        }
        
        fsm_debug("CONSOL_INTER_SIG: [FSMGEN_SIGNALS] Found $fsmgen_intermediate_count intermediate signals from FSMGenFull parsing", 3);
    } else {
        fsm_debug("CONSOL_INTER_SIG: [FSMGEN_SIGNALS] No FSM module signals available for scanning", 3);
    }

    # Step 2.6: Normalize runtime ASTs so the live consolidated path can stay AST-first.
    for my $signal_name (keys %all_intermediate_signals) {
        my $signal_info = $all_intermediate_signals{$signal_name};
        my $runtime_ast = $signal_support->resolve_intermediate_signal_runtime_ast($signal_name, $signal_info);
        if ($runtime_ast && blessed($runtime_ast)) {
            fsm_debug("CONSOL_INTER_SIG: [RUNTIME_AST] '$signal_name' normalized via " . ($signal_info->{runtime_ast_source} || 'runtime_ast'), 3);
        } else {
            fsm_debug("CONSOL_INTER_SIG: [RUNTIME_AST] '$signal_name' still lacks AST; compatibility fallback remains", 3);
        }
    }

    # Step 2.7: Normalize intermediate signal widths from native signal metadata or defining ASTs.
    for my $signal_name (keys %all_intermediate_signals) {
        my $signal_info = $all_intermediate_signals{$signal_name};
        my $resolved_width = $signal_support->resolve_intermediate_signal_width($signal_name, $signal_info, \%all_intermediate_signals);
        $signal_info->{width} = $resolved_width;
        fsm_debug("CONSOL_INTER_SIG: [WIDTH] '$signal_name' width normalized to $resolved_width", 3);
    }

    # Step 2.8: Normalize dependency metadata so the live path consumes AST-first cached dependencies.
    for my $signal_name (keys %all_intermediate_signals) {
        my $signal_info = $all_intermediate_signals{$signal_name};
        my @dependencies = $signal_support->resolve_intermediate_signal_dependencies($signal_name, $signal_info);
        my $dependency_summary = @dependencies ? join(', ', @dependencies) : 'none';
        fsm_debug("CONSOL_INTER_SIG: [DEPENDENCIES] '$signal_name' => $dependency_summary via " . ($signal_info->{dependency_source} || 'none'), 3);
    }

    # Step 2.9: Normalize rendered expressions so downstream phases reuse one cached rendering path.
    for my $signal_name (keys %all_intermediate_signals) {
        my $signal_info = $all_intermediate_signals{$signal_name};
        my $rendered_expression = $signal_support->render_intermediate_signal_expression($signal_name, $signal_info);
        my $render_source = $signal_info->{rendered_expression_source} || 'none';
        if (defined($rendered_expression) && $rendered_expression ne '') {
            fsm_debug("CONSOL_INTER_SIG: [RENDER] '$signal_name' cached via $render_source", 3);
        } else {
            fsm_debug("CONSOL_INTER_SIG: [RENDER] '$signal_name' has no cached renderable expression", 3);
        }
    }

    # Step 2.10: Normalize live usage metadata so filtering consumes cached AST-derived usage facts.
    for my $signal_name (keys %all_intermediate_signals) {
        my $signal_info = $all_intermediate_signals{$signal_name};
        my $live_usage = $ctx->{enable_graph}->resolve_intermediate_signal_live_usage($signal_name, $signal_info);
        my $usage_summary = $live_usage->{evidence_state} || 'none';
        fsm_debug("CONSOL_INTER_SIG: [LIVE_USAGE] '$signal_name' => $usage_summary via " . ($live_usage->{source} || 'ast_live_usage_metadata'), 3);
    }
    
    # Step 3: Apply dependency-aware filtering to prevent referenced signals from being filtered out
    fsm_debug("\n*** DEPENDENCY-AWARE FILTERING PHASE ***", 3);
    
    # Step 3a: Build dependency map from intermediate signal expressions
    my %signal_dependencies = ();  # signal_name => [list of signals it depends on]
    
    for my $signal_name (keys %all_intermediate_signals) {
        my $signal_info = $all_intermediate_signals{$signal_name};
        my @referenced_signals = $signal_support->resolve_intermediate_signal_dependencies($signal_name, $signal_info);
        
        # Find all intermediate signals referenced in this expression
        if (@referenced_signals) {
            $signal_dependencies{$signal_name} = [@referenced_signals];
            fsm_debug("  DEPENDENCY: '$signal_name' depends on: " . join(", ", @referenced_signals), 3);
        }
    }
    
    # Step 3b: Apply initial filtering pass
    my %initially_filtered_signals;
    my %initially_kept_signals;
    
    for my $signal_name (keys %all_intermediate_signals) {
        my $signal_info = $all_intermediate_signals{$signal_name};
        
        # Get expression for filtering analysis
        my $expression = $signal_support->render_intermediate_signal_expression($signal_name, $signal_info);
        unless (defined($expression) && $expression ne '') {
            next;
        }
        
        # Apply filtering logic
        my $should_filter = $signal_support->should_filter_consolidated_signal($expression, $signal_name, $signal_info);
        if ($should_filter) {
            $initially_filtered_signals{$signal_name} = $signal_info;
            fsm_debug("  INITIAL FILTER: '$signal_name' = $expression (would be filtered)", 3);
        } else {
            $initially_kept_signals{$signal_name} = $signal_info;
            fsm_debug("  INITIAL KEEP: '$signal_name' = $expression (would be kept)", 3);
        }
    }
    
    # Step 3c: Dependency propagation - rescue filtered signals that are needed by kept signals
    my %rescued_signals = ();
    
    # Check each kept signal's dependencies
    for my $kept_signal (keys %initially_kept_signals) {
        if ($signal_dependencies{$kept_signal}) {
            for my $dependency (@{$signal_dependencies{$kept_signal}}) {
                # If the dependency was initially filtered but exists in our signal set, rescue it
                if ($initially_filtered_signals{$dependency}) {
                    $rescued_signals{$dependency} = $initially_filtered_signals{$dependency};
                    fsm_debug("  RESCUED: Signal '$dependency' rescued because it's needed by '$kept_signal'", 3);
                }
            }
        }
    }
    
    # Step 3d: Build final filtered signal set
    my %filtered_signals = (%initially_kept_signals, %rescued_signals);
    
    # Final summary
    my $initially_kept_count = scalar(keys %initially_kept_signals);
    my $rescued_count = scalar(keys %rescued_signals);
    my $filtered_count = scalar(keys %initially_filtered_signals) - $rescued_count;
    my $total_kept = scalar(keys %filtered_signals);
    
    fsm_debug("\n*** DEPENDENCY-AWARE FILTERING SUMMARY ***", 3);
    fsm_debug("  Initially kept: $initially_kept_count signals", 3);
    fsm_debug("  Rescued by dependencies: $rescued_count signals", 3);
    fsm_debug("  Actually filtered out: $filtered_count signals", 3);
    fsm_debug("  Total signals kept: $total_kept signals", 3);
    
    # Debug list of rescued signals
    if (%rescued_signals) {
        for my $rescued_signal (sort keys %rescued_signals) {
            my $signal_info = $rescued_signals{$rescued_signal};
            my $expression = $signal_support->render_intermediate_signal_expression($rescued_signal, $signal_info);
            fsm_debug("    RESCUED: $rescued_signal = $expression", 3);
        }
    }
    
    # Debug list of finally filtered signals
    my %finally_filtered = %initially_filtered_signals;
    for my $rescued (keys %rescued_signals) {
        delete $finally_filtered{$rescued};
    }
    if (%finally_filtered) {
        for my $filtered_signal (sort keys %finally_filtered) {
            my $signal_info = $finally_filtered{$filtered_signal};
            my $expression = $signal_support->render_intermediate_signal_expression($filtered_signal, $signal_info);
            fsm_debug("    FILTERED OUT: $filtered_signal = $expression", 3);
        }
    }
    
    fsm_debug("*** DEPENDENCY-AWARE FILTERING COMPLETE ***\n", 3);
    
    # Step 4a: LHS signal declarations are emitted once in generate_internal_signal_declarations().
    # Avoid redeclaring them here with incompatible types.
    
    # Step 4b: Generate HDL for consolidated intermediate signals
    if (%filtered_signals) {
        $hdl .= "  // Consolidated intermediate signals (AST factorization + pre-scan)\n";
        
        # Perform topological sort to ensure dependencies are declared before use
        my @sorted_signals = $self->topologically_sort_signals(\%filtered_signals, \%signal_dependencies);
        
        # First pass: Generate all wire declarations
        for my $signal_name (@sorted_signals) {
            my $signal_info = $filtered_signals{$signal_name};
            my $width = $signal_support->resolve_intermediate_signal_width($signal_name, $signal_info, \%filtered_signals);
            
            # Generate wire declaration
            if ($width > 1) {
                $hdl .= "  wire [" . ($width - 1) . ":0] $signal_name;\n";
            } else {
                $hdl .= "  wire $signal_name;\n";
            }
        }
        
        $hdl .= "\n";  # Add spacing between declarations and assignments
        
        # Second pass: Generate all assign statements
        for my $signal_name (@sorted_signals) {
            my $signal_info = $filtered_signals{$signal_name};
            my $source = $signal_info->{source};
            
            my $expression = $signal_support->render_intermediate_signal_expression($signal_name, $signal_info);
            unless (defined($expression) && $expression ne '') {
                fsm_debug("CONSOL_INTER_SIG: WARNING - No renderable expression for $signal_name, skipping assign emission", 3);
                next;
            }
            
            $hdl .= "  assign $signal_name = $expression; // Source: $source\n";
            
            fsm_debug("  CONSOLIDATED: wire $signal_name = $expression (source: $source)", 3);
        }
        
        $hdl .= "\n";
    } else {
        fsm_debug("  No consolidated intermediate signals needed after filtering", 3);
    }
    
    fsm_debug("*** CONSOLIDATED INTERMEDIATE SIGNAL GENERATION COMPLETE ***\n", 3);
    
    return $hdl;
}
sub topologically_sort_signals ($self, $filtered_signals, $signal_dependencies) {
    fsm_debug("TOPO_SORT: Starting topological sort of intermediate signals", 3);
    fsm_debug("TOPO_SORT: Input signals: " . scalar(keys %$filtered_signals), 3);
    fsm_debug("TOPO_SORT: Dependencies: " . scalar(keys %$signal_dependencies), 3);
    
    # Initialize tracking structures
    my @sorted_signals;
    my %visited;           # Permanent mark (already processed)
    my %temp_visited;      # Temporary mark (currently being processed)
    my %in_degree;         # Count of dependencies for each signal
    
    # Calculate in-degrees for all signals
    for my $signal (keys %$filtered_signals) {
        $in_degree{$signal} = 0;
    }
    
    for my $signal (keys %$signal_dependencies) {
        my $deps = $signal_dependencies->{$signal};
        for my $dep (@$deps) {
            if (exists $filtered_signals->{$dep}) {
                $in_degree{$signal}++;
            }
        }
    }
    
    # Debug initial in-degrees
    fsm_debug("TOPO_SORT: Initial in-degrees:", 3);
    for my $signal (sort keys %in_degree) {
        fsm_debug("  $signal: $in_degree{$signal} dependencies", 3);
    }
    
    # Kahn's algorithm: start with signals that have no dependencies
    my @queue = grep { $in_degree{$_} == 0 } keys %$filtered_signals;
    
    fsm_debug("TOPO_SORT: Starting with " . scalar(@queue) . " signals with no dependencies: " . join(", ", @queue), 3);
    
    while (@queue) {
        my $current = shift @queue;
        push @sorted_signals, $current;
        $visited{$current} = 1;
        
        fsm_debug("  Processing signal: $current", 3);
        
        # Find signals that depend on the current signal
        for my $signal (keys %$signal_dependencies) {
            next if $visited{$signal};
            
            my $deps = $signal_dependencies->{$signal};
            if (grep { $_ eq $current } @$deps) {
                $in_degree{$signal}--;
                fsm_debug("    Reduced in-degree of $signal to $in_degree{$signal}", 3);
                
                if ($in_degree{$signal} == 0) {
                    push @queue, $signal;
                    fsm_debug("    Added $signal to queue (all dependencies satisfied)", 3);
                }
            }
        }
    }
    
    # Check for circular dependencies
    my @remaining_signals = grep { !$visited{$_} } keys %$filtered_signals;
    if (@remaining_signals) {
        fsm_debug("TOPO_SORT: WARNING - Potential circular dependencies detected:", 3);
        for my $signal (@remaining_signals) {
            fsm_debug("  $signal (in-degree: $in_degree{$signal})", 3);
            # Add remaining signals to the end in alphabetical order as fallback
            push @sorted_signals, $signal;
        }
    }
    
    fsm_debug("TOPO_SORT: Final sorted order: " . join(", ", @sorted_signals), 3);
    fsm_debug("TOPO_SORT: Topological sort complete", 3);
    
    return @sorted_signals;
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
