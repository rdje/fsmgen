package FSM::Synthesis::EnableGraph::EnableSupport;

=head1 NAME

FSM::Synthesis::EnableGraph::EnableSupport - Own enable-condition initialization, prescan, and unified WEN/EN emission support for EnableGraph

=head1 DESCRIPTION

This package owns the bounded enable-family support that used to live inline
inside C<FSM::Synthesis::EnableGraph>. It centralizes:

=over 4

=item *

state and standalone-DT enable-condition initialization

=item *

top-level state/DT enable rendering

=item *

prescanning WEN/EN ASTs for referenced intermediate signals

=item *

DT-specific and LHS-level unified WEN/EN emission from prepared assignment
analysis

=back

The broader C<EnableGraph> owner still provides AST capture, AST rendering,
and naming helpers consumed by this support family.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use Scalar::Util qw(blessed);
use Data::Dumper;

use FSM::Debug;

=head2 new

Construct an enable-support owner bound to one live
C<FSM::HDL::FlattenedDT> context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[EnableSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 generate_unified_wen_en_signals

Emit the prepared unified WEN/EN block from assignment-analysis metadata.

=cut

sub generate_unified_wen_en_signals ($self, $fsm_module = undef) {
    my $hdl = "  // Unified WEN/EN Signal Generation from Phase 1 Analysis\n";

    fsm_debug("\n\n*** UNIFIED PHASE 2: GENERATING WEN/EN SIGNALS FROM ANALYSIS ***", 3);

    $hdl .= $self->generate_dt_enables_from_analysis();
    $hdl .= $self->generate_lhs_enables_from_analysis();

    fsm_debug("*** UNIFIED PHASE 2 COMPLETE ***", 3);
    return $hdl;
}

=head2 prescan_wen_en_for_intermediate_signals

Scan the prepared WEN/EN ASTs and record referenced intermediate signals that
still need declarations.

=cut

sub prescan_wen_en_for_intermediate_signals ($self) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("\n*** PRE-SCAN: IDENTIFYING INTERMEDIATE SIGNALS NEEDED FOR WEN/EN ***", 3);
    fsm_debug("*** TIMING DEBUG: PRE-SCAN running WITHOUT logical operation counts! ***", 3);

    if (exists $ctx->{binary_logical_op_counts}) {
        my $total_ops = 0;
        for my $count (values %{$ctx->{binary_logical_op_counts}}) {
            $total_ops += $count;
        }
        fsm_debug("PRE-SCAN: Logical operation counts ARE available: $total_ops total ops", 3);
        fsm_debug("PRE-SCAN: Counts: " . Data::Dumper::Dumper($ctx->{binary_logical_op_counts}));
    } else {
        fsm_debug("*** PRE-SCAN: CRITICAL - Logical operation counts NOT available yet! ***", 3);
        fsm_debug("*** This means pre-scan is creating intermediate signals blindly! ***", 3);
    }

    $ctx->{referenced_intermediate_signals} //= {};

    for my $state_name (sort keys %{$ctx->{state_enables} || {}}) {
        my $enable_ast = $ctx->{state_enables}{$state_name};
        next unless $enable_ast && blessed($enable_ast);

        fsm_debug("  PRE-SCAN: Scanning state-DT DTE: $state_name", 3);
        $ctx->{enable_graph_intermediate_support}->track_ast_intermediate_signals($enable_ast);
    }

    for my $dt_name (sort keys %{$ctx->{dt_enables} || {}}) {
        my $enable_ast = $ctx->{dt_enables}{$dt_name};
        next unless $enable_ast && blessed($enable_ast);

        fsm_debug("  PRE-SCAN: Scanning standalone-DT DTE: $dt_name", 3);
        $ctx->{enable_graph_intermediate_support}->track_ast_intermediate_signals($enable_ast);
    }

    for my $lhs (sort keys %{$ctx->{assignment_analysis}}) {
        my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};

        for my $rhs (sort keys %{$lhs_analysis->{rhs_groups}}) {
            my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};

            for my $dt_enable_info (@{$rhs_group->{dt_specific_enables}}) {
                my $enable_ast = $dt_enable_info->{enable_ast};
                next unless $enable_ast && blessed($enable_ast);

                fsm_debug("  PRE-SCAN: Scanning DT-specific enable: $dt_enable_info->{enable_name}", 3);
                $ctx->{enable_graph_intermediate_support}->track_ast_intermediate_signals($enable_ast);
            }

            if ($rhs_group->{lhs_level_enable} && $rhs_group->{lhs_level_enable}->{ast}) {
                my $lhs_enable = $rhs_group->{lhs_level_enable};
                my $enable_ast = $lhs_enable->{ast};
                next unless $enable_ast && blessed($enable_ast);

                fsm_debug("  PRE-SCAN: Scanning LHS-level enable: $lhs_enable->{name}", 3);
                $ctx->{enable_graph_intermediate_support}->track_ast_intermediate_signals($enable_ast);
            }
        }
    }

    my $signal_count = scalar(keys %{$ctx->{referenced_intermediate_signals}});
    fsm_debug("PRE-SCAN: Identified $signal_count intermediate signals that need declaration", 3);

    if ($signal_count > 0) {
        for my $signal_name (sort keys %{$ctx->{referenced_intermediate_signals}}) {
            fsm_debug("  - $signal_name", 3);
        }
    }

    fsm_debug("*** PRE-SCAN COMPLETE ***\n", 3);
}

=head2 generate_enable_conditions

Emit the top-level state and standalone-DT enable assignments from the
prepared enable registries.

=cut

sub generate_enable_conditions ($self, $fsm_module = undef) {
    my $ctx = $self->{flattened_dt};
    my $ast_support = $ctx->{enable_graph_ast_support};
    my $hdl = "  // State and DT Enable Conditions\n";

    for my $state_name (sort keys %{$ctx->{state_enables}}) {
        my $enable_expr = $ctx->{state_enables}->{$state_name};
        $enable_expr = blessed($enable_expr) && $ast_support
            ? $ast_support->ast_to_systemverilog($enable_expr)
            : blessed($enable_expr) && $enable_expr->can('to_systemverilog')
                ? $enable_expr->to_systemverilog
            : $enable_expr;
        $hdl .= "  assign ${state_name}_en = $enable_expr;\n";
    }

    for my $dt_name (sort keys %{$ctx->{dt_enables}}) {
        my $enable_expr = $ctx->{dt_enables}->{$dt_name};
        $enable_expr = blessed($enable_expr) && $ast_support
            ? $ast_support->ast_to_systemverilog($enable_expr)
            : blessed($enable_expr) && $enable_expr->can('to_systemverilog')
                ? $enable_expr->to_systemverilog
            : $enable_expr;
        my $clean_name = $dt_name;
        $clean_name =~ s/^-//;
        $hdl .= "  assign ${clean_name}_en = $enable_expr;\n";
    }

    $hdl .= "\n";
    return $hdl;
}

=head2 generate_dt_enables_from_analysis

Emit the DT-specific enable assignments from the prepared assignment-analysis
structure.

=cut

sub generate_dt_enables_from_analysis ($self) {
    my $ctx = $self->{flattened_dt};
    my $enable_graph_ast_support = $ctx->{enable_graph_ast_support};

    fsm_debug("GENERATE_DT_ENABLES: [ENTRY] Starting DT-specific enable generation from analysis", 3);
    my $hdl = "  // DT-Specific Enable Signals from Unified Analysis\n";

    $ctx->{referenced_intermediate_signals} //= {};
    fsm_debug("GENERATE_DT_ENABLES: [INIT] Initialized referenced_intermediate_signals tracking", 3);

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

                fsm_debug("GENERATE_DT_ENABLES: [TRACK_INTERMEDIATE] Tracking intermediate signals for '$enable_name'", 3);
                $ctx->{enable_graph_intermediate_support}->track_ast_intermediate_signals($enable_ast);

                $dt_to_lhs_enables{$dt_name} //= {};
                $dt_to_lhs_enables{$dt_name}{$lhs} //= [];
                fsm_debug("GENERATE_DT_ENABLES: [GROUPING] Grouping enable '$enable_name' under DT '$dt_name' LHS '$lhs'", 3);

                push @{$dt_to_lhs_enables{$dt_name}{$lhs}}, {
                    enable_name => $enable_name,
                    enable_ast => $enable_ast,
                    dte_gate_ast => $dt_enable_info->{dte_gate_ast},
                    dte_gate_signal => $dt_enable_info->{dte_gate_signal},
                    rhs => $rhs,
                };
            }
        }
    }

    for my $dt_name (sort keys %dt_to_lhs_enables) {
        $hdl .= "\n\n  // === DT: $dt_name ===\n";

        for my $lhs (sort keys %{$dt_to_lhs_enables{$dt_name}}) {
            $hdl .= "  // $lhs\n";

            for my $enable_info (@{$dt_to_lhs_enables{$dt_name}{$lhs}}) {
                my $enable_name = $enable_info->{enable_name};
                my $enable_ast = $enable_info->{enable_ast};
                my $rhs = $enable_info->{rhs};

                my $boundary_gated_ast = $self->build_boundary_gated_dt_enable_ast($enable_info);
                my $enable_expr = $enable_graph_ast_support->ast_to_systemverilog($boundary_gated_ast);
                $hdl .= "  assign $enable_name = $enable_expr;  // $lhs <- $rhs\n";

                fsm_debug("  Generated DT-specific enable: $enable_name = $enable_expr", 3);
            }
        }
    }

    return $hdl;
}

=head2 build_boundary_gated_dt_enable_ast

Build the final output-enable AST for one DT-specific enable.

The stored C<enable_ast> is the DT-local selector predicate. The DTE is kept
separate so state enables are applied at the DT output boundary instead of
being absorbed into internal factored selector helpers.

=cut

sub build_boundary_gated_dt_enable_ast ($self, $dt_enable_info) {
    my $selector_ast = $dt_enable_info->{enable_ast};
    my $dte_gate_ast = $dt_enable_info->{dte_gate_ast};

    return $selector_ast unless $dte_gate_ast && blessed($dte_gate_ast);
    return $dte_gate_ast unless $selector_ast && blessed($selector_ast);

    return FSM::AST::Utils::and_op($dte_gate_ast, $selector_ast);
}

=head2 generate_lhs_enables_from_analysis

Emit the grouped LHS-level enables from the prepared assignment-analysis
structure.

=cut

sub generate_lhs_enables_from_analysis ($self) {
    my $ctx = $self->{flattened_dt};
    my $enable_graph_ast_support = $ctx->{enable_graph_ast_support};
    my $hdl = "\n  // LHS-Level Enable Signals from Unified Analysis\n";

    for my $lhs (sort keys %{$ctx->{assignment_analysis}}) {
        my $lhs_analysis = $ctx->{assignment_analysis}->{$lhs};

        $hdl .= "\n  // LHS-level enables for: $lhs\n";

        for my $rhs (sort keys %{$lhs_analysis->{rhs_groups}}) {
            my $rhs_group = $lhs_analysis->{rhs_groups}->{$rhs};
            my $lhs_enable = $rhs_group->{lhs_level_enable};

            if ($lhs_enable) {
                my $enable_name = $lhs_enable->{name};
                my $enable_ast = $lhs_enable->{ast};

                $ctx->{enable_graph_intermediate_support}->track_ast_intermediate_signals($enable_ast);

                my $enable_expr = $enable_graph_ast_support->ast_to_systemverilog($enable_ast);

                $hdl .= "  assign $enable_name = $enable_expr;\n";

                fsm_debug("  Generated LHS-level enable: $enable_name = $enable_expr", 3);
            }
        }
    }

    return $hdl;
}

=head2 build_state_enable_condition_ast

Build the top-level enable AST for one regular FSM state.

=cut

sub build_state_enable_condition_ast ($self, $state_name, $state = undef) {
    my $state_decode_ast = FSM::AST::Utils::equals_op(
        FSM::AST::Utils::signal_ref('current_state'),
        FSM::AST::Utils::literal(uc($state_name)),
    );

    if ($state && $state->can('dt_enable_condition')) {
        my $condition_ast = $state->dt_enable_condition;
        return FSM::AST::Utils::bitwise_or($state_decode_ast, $condition_ast)
            if $condition_ast && blessed($condition_ast);
    }

    return $state_decode_ast;
}

=head2 build_dt_enable_condition_ast

Build the top-level enable AST for one standalone DT.

=cut

sub build_dt_enable_condition_ast ($self, $dt_name, $state = undef) {
    if ($state && $state->can('dt_enable_condition')) {
        my $condition_ast = $state->dt_enable_condition;
        return $condition_ast if $condition_ast && blessed($condition_ast);
    }

    return FSM::AST::Utils::literal("1'b1");
}

=head2 initialize_state_and_dt_enable_conditions

Populate the top-level state and standalone-DT enable registries from one FSM
module.

=cut

sub initialize_state_and_dt_enable_conditions ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    $ctx->{state_enables} = {};
    $ctx->{dt_enables} = {};

    return unless $fsm_module && $fsm_module->can('states') && $fsm_module->states;

    for my $state (@{$fsm_module->states}) {
        next unless $state && $state->can('name');

        my $state_name = $state->name;
        next unless defined($state_name) && $state_name ne '';

        if ($state->can('is_regular_state') ? !$state->is_regular_state : $state_name =~ /^-/) {
            my $enable_ast = $self->build_dt_enable_condition_ast($state_name, $state);
            $ctx->{dt_enables}->{$state_name} = $enable_ast;
            my $enable_sv = blessed($enable_ast) && $enable_ast->can('to_systemverilog')
                ? $enable_ast->to_systemverilog
                : 'UNBLESSED';
            fsm_debug("ENABLE_INIT: Registered standalone DT enable for $state_name -> $enable_sv", 3);
        } else {
            my $enable_ast = $self->build_state_enable_condition_ast($state_name, $state);
            $ctx->{state_enables}->{$state_name} = $enable_ast;
            my $enable_sv = blessed($enable_ast) && $enable_ast->can('to_systemverilog')
                ? $enable_ast->to_systemverilog
                : 'UNBLESSED';
            fsm_debug("ENABLE_INIT: Registered state enable for $state_name -> $enable_sv", 3);
        }
    }
}

1;
