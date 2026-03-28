package FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalSupport - Own direct SystemVerilog intermediate-signal filter support

=head1 DESCRIPTION

Owns the bounded filter-policy family for the older direct generated-module
SystemVerilog backend. This package now centralizes:

=over 4

=item *

AST-aware filter policy over normalized intermediate signal metadata

=item *

runtime-AST-miss filter fallback based on live-usage evidence

=item *

small AST-shape predicates used by that filter policy

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport>
now owns runtime-AST lookup, dependency recovery, rendered-expression caching,
and width inference. This package is the narrower “should we keep this
intermediate in the emitted HDL?” owner.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;
use Scalar::Util qw(blessed);

=head2 new

Construct one intermediate-signal filter owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[IntermediateSignalSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 should_filter_consolidated_signal

Apply the AST-first filter decision for one consolidated intermediate signal,
falling back to explicit runtime-AST-miss filtering when no runtime AST can be
resolved.

=cut

sub should_filter_consolidated_signal ($self, $expression, $signal_name, $signal_info) {
    my $ctx = $self->{flattened_dt};
    my $recovery_support = $ctx->{backend_sv_intermediate_recovery_support};
    # AST-BASED FILTERING - Use semantic analysis instead of string patterns
    # This replaces the old string-based regex filtering with proper AST analysis

    $expression = $recovery_support->render_intermediate_signal_expression($signal_name, $signal_info)
        unless defined($expression) && $expression ne '';
    fsm_debug("\n*** AST_FILTER_CHECK: Analyzing signal '$signal_name' ***", 3);
    fsm_debug("  Expression: '$expression'", 3);
    fsm_debug("  Source: $signal_info->{source}", 3);
    fsm_debug("  Usage count: " . ($signal_info->{usage_count} || 'unknown'));

    # Try to get the AST for this signal if available
    my $ast = $recovery_support->resolve_intermediate_signal_runtime_ast($signal_name, $signal_info);
    if ($ast && blessed($ast)) {
        fsm_debug("  Using runtime AST for filtering: " . ref($ast), 3);
    } else {
        my $miss_reason = ($signal_info && ref($signal_info) eq 'HASH')
            ? ($signal_info->{runtime_ast_miss_reason} || 'unknown_runtime_ast_miss')
            : 'unknown_runtime_ast_miss';
        fsm_debug("  No runtime AST available - falling back to explicit runtime-AST-miss filtering ($miss_reason)", 3);
    }

    # AST-based filtering when AST is available
    if ($ast && blessed($ast)) {
        return $self->should_filter_ast_based($ast, $signal_name, $signal_info);
    }

    # Fallback to explicit runtime-AST-miss filtering (legacy-named helper delegates here).
    return $self->should_filter_runtime_ast_miss($signal_name, $signal_info);
}


=head2 should_filter_ast_based

Apply the AST-aware filter policy when a runtime AST is available.

=cut

sub should_filter_ast_based ($self, $ast, $signal_name, $signal_info) {
    my $ctx = $self->{flattened_dt};
    # Pure AST-based filtering using semantic analysis

    fsm_debug("  AST_FILTER: Using AST-based filtering for " . ref($ast));

    my $usage_count = $signal_info->{usage_count} || 0;
    my $live_usage = $ctx->{enable_graph_factorization_support}->resolve_intermediate_signal_live_usage($signal_name, $signal_info);
    my $actually_used = $live_usage->{used_in_final_expressions} ? 1 : 0;

    # REFERENCE-AWARE FILTERING: Check if signal is referenced in substituted expressions
    # This is the fix for the bug where intermediate signals are referenced but not declared
    my $referenced_in_substitutions = $live_usage->{referenced_in_substitutions} ? 1 : 0;

    if ($referenced_in_substitutions) {
        fsm_debug("  AST_FILTER: Signal '$signal_name' is referenced in AST substitutions - KEEPING", 3);
        return 0; # Keep signals that are already referenced in substituted expressions
    }

    # AST_FILTER 1: TEMPORARILY DISABLED - Filter if not actually used
    # The usage tracking is not working correctly after AST substitution
    # So we're temporarily disabling this aggressive filtering
    if (!$actually_used || $usage_count == 0) {
        fsm_debug("  AST_FILTER: Signal appears unused (usage_count=$usage_count, actually_used=$actually_used) - but KEEPING due to usage tracking issues", 3);
        # return 1;  # DISABLED - usage tracking is broken
    }

    # AST_FILTER 2: Filter simple literals
    if ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal')) {
        fsm_debug("  AST_FILTER: Simple literal - FILTERING", 3);
        return 1;
    }

    # AST_FILTER 3: Filter bare signal references (signal = signal)
    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        fsm_debug("  AST_FILTER: Bare signal reference - FILTERING", 3);
        return 1;
    }

    # AST_FILTER 4: Handle unary operations (like negation)
    if ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        # Check if it's a simple negation of a signal
        if ($self->is_simple_negation($ast)) {
            # Only factor if used multiple times
            if ($usage_count >= 2) {
                fsm_debug("  AST_FILTER: Simple negation used $usage_count times - KEEPING", 3);
                return 0;
            } else {
                fsm_debug("  AST_FILTER: Simple negation used only once - FILTERING", 3);
                return 1;
            }
        } else {
            # Complex unary operation - always keep
            fsm_debug("  AST_FILTER: Complex unary operation - KEEPING", 3);
            return 0;
        }
    }

    # AST_FILTER 5: Handle binary operations
    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        # Check if it's a simple comparison
        if ($self->is_simple_comparison($ast)) {
            fsm_debug("  AST_FILTER: Simple comparison - FILTERING", 3);
            return 1;
        }

        # Check if it's an arithmetic operation (always keep)
        if ($ctx->{enable_graph_ast_support}->is_arithmetic_operation($ast)) {
            fsm_debug("  AST_FILTER: Arithmetic operation - KEEPING", 3);
            return 0;
        }

        # Check if it's a logical operation
        if ($ctx->{enable_graph_ast_support}->is_logical_operation($ast)) {
            # Use the existing AST-based logical operation factorization logic
            my $should_factor = $ctx->{enable_graph_ast_support}->should_factor_logical_operation($ast);
            if ($should_factor && $usage_count >= 2) {
                fsm_debug("  AST_FILTER: Multi-use logical operation - KEEPING", 3);
                return 0;
            } else {
                fsm_debug("  AST_FILTER: Low-use logical operation - FILTERING", 3);
                return 1;
            }
        }

        # Other binary operations - keep if used multiple times
        if ($usage_count >= 2) {
            fsm_debug("  AST_FILTER: Multi-use binary operation - KEEPING", 3);
            return 0;
        } else {
            fsm_debug("  AST_FILTER: Single-use binary operation - FILTERING", 3);
            return 1;
        }
    }

    # Default: keep complex expressions that are used multiple times
    if ($usage_count >= 2) {
        fsm_debug("  AST_FILTER: Complex multi-use expression - KEEPING", 3);
        return 0;
    } else {
        fsm_debug("  AST_FILTER: Complex single-use expression - FILTERING", 3);
        return 1;
    }
}

=head2 should_filter_runtime_ast_miss

Apply the live-usage filter fallback for signals that still lack a runtime
AST.

=cut

sub should_filter_runtime_ast_miss ($self, $signal_name, $signal_info) {
    my $miss_reason = ($signal_info && ref($signal_info) eq 'HASH')
        ? ($signal_info->{runtime_ast_miss_reason} || 'unknown_runtime_ast_miss')
        : 'unknown_runtime_ast_miss';
    my $live_usage = $self->{flattened_dt}->{enable_graph_factorization_support}->resolve_intermediate_signal_live_usage($signal_name, $signal_info);
    my $referenced_in_substitutions = $live_usage->{referenced_in_substitutions} ? 1 : 0;
    my $used_in_final_expressions = $live_usage->{used_in_final_expressions} ? 1 : 0;
    my $evidence_state = $live_usage->{evidence_state} || 'none';

    if ($signal_info && ref($signal_info) eq 'HASH') {
        $signal_info->{filter_fallback_source} = 'runtime_ast_miss_live_usage';
        $signal_info->{filter_fallback_reason} = $miss_reason;
    }

    fsm_debug("  RUNTIME_AST_MISS_FILTER: Evaluating '$signal_name' via live usage metadata ($evidence_state, miss_reason=$miss_reason)", 3);

    if ($referenced_in_substitutions) {
        fsm_debug("  RUNTIME_AST_MISS_FILTER: Signal '$signal_name' is referenced in AST substitutions - KEEPING", 3);
        return 0;
    }

    if ($used_in_final_expressions) {
        fsm_debug("  RUNTIME_AST_MISS_FILTER: Signal '$signal_name' is used in final AST expressions - KEEPING", 3);
        return 0;
    }

    fsm_debug("  RUNTIME_AST_MISS_FILTER: No AST-backed live-usage evidence for '$signal_name' - FILTERING", 3);
    return 1;
}

=head2 is_simple_negation

Return true when the AST is a simple unary negation over a signal reference.

=cut

sub is_simple_negation ($self, $ast) {
    # Check if this is a simple negation of a signal (like !signal_name)
    return 0 unless $ast && blessed($ast);
    return 0 unless $ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp');
    return 0 unless $ast->can('operator') && $ast->can('operand');

    my $op = $ast->operator || '';
    return 0 unless $op =~ /^(!|not)$/;

    my $operand = $ast->operand;
    return 0 unless $operand && blessed($operand);

    # Check if operand is a simple signal reference
    return ($operand->isa('FSM::AST::SignalRef') || $operand->isa('FSM::CoreAST::SignalRef'));
}

=head2 is_simple_comparison

Return true when the AST is a simple signal-versus-literal comparison.

=cut

sub is_simple_comparison ($self, $ast) {
    # Check if this is a simple comparison like signal == constant
    return 0 unless $ast && blessed($ast);
    return 0 unless $ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp');
    return 0 unless $ast->can('operator') && $ast->can('left') && $ast->can('right');

    my $op = $ast->operator || '';
    return 0 unless $op =~ /^(==|!=|<|>|<=|>=)$/;

    my $left = $ast->left;
    my $right = $ast->right;
    return 0 unless $left && blessed($left) && $right && blessed($right);

    # Check if one side is a signal and the other is a literal
    my $has_signal = ($left->isa('FSM::AST::SignalRef') || $left->isa('FSM::CoreAST::SignalRef')) ||
                     ($right->isa('FSM::AST::SignalRef') || $right->isa('FSM::CoreAST::SignalRef'));
    my $has_literal = ($left->isa('FSM::AST::Literal') || $left->isa('FSM::CoreAST::Literal')) ||
                      ($right->isa('FSM::AST::Literal') || $right->isa('FSM::CoreAST::Literal'));

    return $has_signal && $has_literal;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one intermediate-signal filter owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 should_filter_consolidated_signal

Applies the AST-first filter decision for one consolidated intermediate
signal, falling back to explicit runtime-AST-miss filtering when no runtime
AST can be resolved.

=head2 should_filter_ast_based

Applies the AST-aware filter policy when a runtime AST is available.

=head2 should_filter_runtime_ast_miss

Applies the live-usage filter fallback for signals that still lack a runtime
AST.

=head2 is_simple_negation

Returns true when the AST is a simple unary negation over a signal reference.

=head2 is_simple_comparison

Returns true when the AST is a simple signal-versus-literal comparison.

=cut
