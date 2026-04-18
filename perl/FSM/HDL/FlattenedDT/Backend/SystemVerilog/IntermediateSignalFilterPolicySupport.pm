package FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalFilterPolicySupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalFilterPolicySupport - Own direct intermediate-signal filter heuristics

=head1 DESCRIPTION

Owns the bounded heuristic family for the older direct generated-module
SystemVerilog intermediate-signal path. This package centralizes:

=over 4

=item *

AST-aware filter policy over normalized intermediate signal metadata

=item *

runtime-AST-miss filter fallback based on live-usage evidence

=item *

small AST-shape predicates used by that filter policy

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalSupport>
now narrows to consolidated-signal filter dispatch, while this package owns the
actual keep/filter heuristic decisions.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;
use Scalar::Util qw(blessed);

=head2 new

Construct one intermediate-signal filter-policy owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[IntermediateSignalFilterPolicySupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 should_filter_ast_based

Apply the AST-aware filter policy when a runtime AST is available.

=cut

sub should_filter_ast_based ($self, $ast, $signal_name, $signal_info) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("  AST_FILTER: Using AST-based filtering for " . ref($ast));

    my $usage_count = $signal_info->{usage_count} || 0;
    my $live_usage = $ctx->{enable_graph_factorization_support}->resolve_intermediate_signal_live_usage($signal_name, $signal_info);
    my $actually_used = $live_usage->{used_in_final_expressions} ? 1 : 0;
    my $referenced_in_substitutions = $live_usage->{referenced_in_substitutions} ? 1 : 0;
    my $source = ref($signal_info) eq 'HASH' ? ($signal_info->{source} || '') : '';

    if ($referenced_in_substitutions) {
        fsm_debug("  AST_FILTER: Signal '$signal_name' is referenced in AST substitutions - KEEPING", 3);
        return 0;
    }

    if ($source eq 'fsmgen_parsing' && $actually_used) {
        fsm_debug("  AST_FILTER: Parser-created intermediate '$signal_name' is still referenced by a final AST - KEEPING", 3);
        return 0;
    }

    if (!$actually_used || $usage_count == 0) {
        fsm_debug("  AST_FILTER: Signal appears unused (usage_count=$usage_count, actually_used=$actually_used) - but KEEPING due to usage tracking issues", 3);
        # return 1;  # Disabled while usage tracking remains intentionally conservative.
    }

    if ($ast->isa('FSM::AST::Literal') || $ast->isa('FSM::CoreAST::Literal')) {
        fsm_debug("  AST_FILTER: Simple literal - FILTERING", 3);
        return 1;
    }

    if ($ast->isa('FSM::AST::SignalRef') || $ast->isa('FSM::CoreAST::SignalRef')) {
        fsm_debug("  AST_FILTER: Bare signal reference - FILTERING", 3);
        return 1;
    }

    if ($ast->isa('FSM::CoreAST::AggregateRef')) {
        fsm_debug("  AST_FILTER: Bare aggregate reference - FILTERING", 3);
        return 1;
    }

    if ($ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp')) {
        if ($self->is_simple_negation($ast)) {
            if ($usage_count >= 2) {
                fsm_debug("  AST_FILTER: Simple negation used $usage_count times - KEEPING", 3);
                return 0;
            }

            fsm_debug("  AST_FILTER: Simple negation used only once - FILTERING", 3);
            return 1;
        }

        fsm_debug("  AST_FILTER: Complex unary operation - KEEPING", 3);
        return 0;
    }

    if ($ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp')) {
        if ($self->is_simple_comparison($ast)) {
            fsm_debug("  AST_FILTER: Simple comparison - FILTERING", 3);
            return 1;
        }

        if ($ctx->{enable_graph_ast_support}->is_arithmetic_operation($ast)) {
            fsm_debug("  AST_FILTER: Arithmetic operation - KEEPING", 3);
            return 0;
        }

        if ($ctx->{enable_graph_ast_support}->is_logical_operation($ast)) {
            my $should_factor = $ctx->{enable_graph_ast_support}->should_factor_logical_operation($ast);
            if ($should_factor && $usage_count >= 2) {
                fsm_debug("  AST_FILTER: Multi-use logical operation - KEEPING", 3);
                return 0;
            }

            fsm_debug("  AST_FILTER: Low-use logical operation - FILTERING", 3);
            return 1;
        }

        if ($usage_count >= 2) {
            fsm_debug("  AST_FILTER: Multi-use binary operation - KEEPING", 3);
            return 0;
        }

        fsm_debug("  AST_FILTER: Single-use binary operation - FILTERING", 3);
        return 1;
    }

    if ($usage_count >= 2) {
        fsm_debug("  AST_FILTER: Complex multi-use expression - KEEPING", 3);
        return 0;
    }

    fsm_debug("  AST_FILTER: Complex single-use expression - FILTERING", 3);
    return 1;
}

=head2 should_filter_runtime_ast_miss

Apply the live-usage filter fallback for signals that still lack a runtime AST.

=cut

sub should_filter_runtime_ast_miss ($self, $signal_name, $signal_info) {
    my $miss_reason = ($signal_info && ref($signal_info) eq 'HASH')
        ? ($signal_info->{runtime_ast_miss_reason} || 'unknown_runtime_ast_miss')
        : 'unknown_runtime_ast_miss';
    my $live_usage = $self->{flattened_dt}->{enable_graph_factorization_support}->resolve_intermediate_signal_live_usage($signal_name, $signal_info);
    my $referenced_in_substitutions = $live_usage->{referenced_in_substitutions} ? 1 : 0;
    my $used_in_final_expressions = $live_usage->{used_in_final_expressions} ? 1 : 0;
    my $evidence_state = $live_usage->{evidence_state} || 'none';
    my $source = ($signal_info && ref($signal_info) eq 'HASH') ? ($signal_info->{source} || '') : '';

    if ($signal_info && ref($signal_info) eq 'HASH') {
        $signal_info->{filter_fallback_source} = 'runtime_ast_miss_live_usage';
        $signal_info->{filter_fallback_reason} = $miss_reason;
    }

    fsm_debug("  RUNTIME_AST_MISS_FILTER: Evaluating '$signal_name' via live usage metadata ($evidence_state, miss_reason=$miss_reason)", 3);

    if ($referenced_in_substitutions) {
        fsm_debug("  RUNTIME_AST_MISS_FILTER: Signal '$signal_name' is referenced in AST substitutions - KEEPING", 3);
        return 0;
    }

    if ($source eq 'fsmgen_parsing' && $used_in_final_expressions) {
        fsm_debug("  RUNTIME_AST_MISS_FILTER: Parser-created intermediate '$signal_name' is still referenced by a final AST - KEEPING", 3);
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
    return 0 unless $ast && blessed($ast);
    return 0 unless $ast->isa('FSM::AST::UnaryOp') || $ast->isa('FSM::CoreAST::UnaryOp');
    return 0 unless $ast->can('operator') && $ast->can('operand');

    my $op = $ast->operator || '';
    return 0 unless $op =~ /^(!|not)$/;

    my $operand = $ast->operand;
    return 0 unless $operand && blessed($operand);

    return (
        $operand->isa('FSM::AST::SignalRef')
        || $operand->isa('FSM::CoreAST::SignalRef')
        || $operand->isa('FSM::CoreAST::AggregateRef')
    );
}

=head2 is_simple_comparison

Return true when the AST is a simple signal-versus-literal comparison.

=cut

sub is_simple_comparison ($self, $ast) {
    return 0 unless $ast && blessed($ast);
    return 0 unless $ast->isa('FSM::AST::BinaryOp') || $ast->isa('FSM::CoreAST::BinaryOp');
    return 0 unless $ast->can('operator') && $ast->can('left') && $ast->can('right');

    my $op = $ast->operator || '';
    return 0 unless $op =~ /^(==|!=|<|>|<=|>=)$/;

    my $left = $ast->left;
    my $right = $ast->right;
    return 0 unless $left && blessed($left) && $right && blessed($right);

    my $has_signal = ($left->isa('FSM::AST::SignalRef') || $left->isa('FSM::CoreAST::SignalRef') || $left->isa('FSM::CoreAST::AggregateRef')) ||
                     ($right->isa('FSM::AST::SignalRef') || $right->isa('FSM::CoreAST::SignalRef') || $right->isa('FSM::CoreAST::AggregateRef'));
    my $has_literal = ($left->isa('FSM::AST::Literal') || $left->isa('FSM::CoreAST::Literal')) ||
                      ($right->isa('FSM::AST::Literal') || $right->isa('FSM::CoreAST::Literal'));

    return $has_signal && $has_literal;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one intermediate-signal filter-policy owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

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
