package FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalSupport - Own direct SystemVerilog intermediate-signal filter support

=head1 DESCRIPTION

Retains the bounded compatibility-shell surface for the older direct
generated-module SystemVerilog backend. This package now centralizes:

=over 4

=item *

the small directly testable dispatcher surface for consolidated intermediate
keep/filter decisions

=item *

runtime-AST lookup handoff to the recovery owner before filtering

=back

This package is no longer instantiated on the live
C<FSM::HDL::FlattenedDT> backend path. The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport>
now owns runtime-AST lookup, dependency recovery, rendered-expression caching,
and width inference, while the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalFilterPolicySupport>
now owns the actual AST-aware and runtime-fallback filter heuristics. This
package remains as the narrower compatibility-shell dispatcher for direct
owner tests and any future bounded callers that still need that exact wrapper.

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
    my $filter_policy_support = $ctx->{backend_sv_intermediate_filter_policy_support};

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

    if ($ast && blessed($ast)) {
        return $filter_policy_support->should_filter_ast_based($ast, $signal_name, $signal_info);
    }

    return $filter_policy_support->should_filter_runtime_ast_miss($signal_name, $signal_info);
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

=cut
