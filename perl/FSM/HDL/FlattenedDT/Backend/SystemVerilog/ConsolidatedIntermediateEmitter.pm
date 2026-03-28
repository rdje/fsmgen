package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateEmitter;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateEmitter - Render direct consolidated intermediate-signal blocks

=head1 DESCRIPTION

Owns the bounded consolidated intermediate-signal emission family for the older
direct generated-module SystemVerilog backend. This package takes the prepared
consolidated intermediate-signal set, applies dependency-aware filtering, and
renders the consolidated wire and assign block that appears before unified
WEN/EN signal generation.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;
use Scalar::Util qw(blessed);

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[ConsolidatedIntermediateEmitter.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

sub generate_consolidated_intermediate_signals ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my $signal_support = $ctx->{backend_sv_intermediate_support};
    my $all_intermediate_signals = $ctx->{backend_sv_consolidated_intermediate_support}
        ->collect_consolidated_intermediate_signals($fsm_module);
    my $hdl = "";

    # Step 3: Apply dependency-aware filtering to prevent referenced signals from being filtered out
    fsm_debug("\n*** DEPENDENCY-AWARE FILTERING PHASE ***", 3);

    # Step 3a: Build dependency map from intermediate signal expressions
    my %signal_dependencies = ();  # signal_name => [list of signals it depends on]

    for my $signal_name (keys %$all_intermediate_signals) {
        my $signal_info = $all_intermediate_signals->{$signal_name};
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

    for my $signal_name (keys %$all_intermediate_signals) {
        my $signal_info = $all_intermediate_signals->{$signal_name};

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

1;

__END__

=head1 METHODS

=head2 new

Constructs one consolidated-intermediate emitter bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 generate_consolidated_intermediate_signals

Builds and renders the consolidated direct-backend intermediate-signal block by
consuming the prepared consolidated signal set, applying dependency-aware
filtering, and emitting the resulting wire and assign family.

=head2 topologically_sort_signals

Returns the dependency-safe emission order for the filtered consolidated
intermediate-signal set, using dependency metadata already normalized by the
support owner and falling back safely when cycles are detected.

=cut
