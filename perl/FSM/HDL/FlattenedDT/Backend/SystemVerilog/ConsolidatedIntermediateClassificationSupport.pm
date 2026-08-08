package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateClassificationSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateClassificationSupport - Own direct consolidated intermediate initial keep/filter classification

=head1 DESCRIPTION

Owns the bounded initial-classification family for the older direct
generated-module SystemVerilog consolidated intermediate path. This package
centralizes:

=over 4

=item *

per-signal rendered-expression lookup before classification

=item *

direct AST-first keep/filter dispatch over the extracted recovery and
filter-policy owners

=item *

the initial kept-versus-filtered partition consumed by downstream
dependency-aware rescue and ordering owners

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSelectionSupport>
now narrows to dependency-aware rescue and final kept/filtered summary
projection, while this package owns the earlier “which signals survive the
first AST-aware filter pass?” decision.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;
use Scalar::Util qw(blessed);

=head2 new

Construct one consolidated-intermediate classification owner bound to a
specific C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[ConsolidatedIntermediateClassificationSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 classify_consolidated_signals

Run the initial AST-aware consolidated intermediate keep/filter classification
and return the resulting first-pass kept and filtered sets.

=cut

sub classify_consolidated_signals ($self, $all_intermediate_signals) {
    my $ctx = $self->{flattened_dt};
    my $recovery_support = $ctx->{backend_sv_intermediate_recovery_support};
    my $filter_policy_support = $ctx->{backend_sv_intermediate_filter_policy_support};
    my $trace_signal_detail = debug_enabled() && debug_level() >= 3;
    my %initially_filtered_signals;
    my %initially_kept_signals;

    for my $signal_name (keys %{ $all_intermediate_signals || {} }) {
        my $signal_info = $all_intermediate_signals->{$signal_name};
        my $expression = $recovery_support->render_intermediate_signal_expression($signal_name, $signal_info);
        next unless defined($expression) && $expression ne '';

        if ($trace_signal_detail) {
            fsm_debug("\n*** AST_FILTER_CHECK: Analyzing signal '$signal_name' ***", 3);
            fsm_debug("  Expression: '$expression'", 3);
            fsm_debug("  Source: $signal_info->{source}", 3);
            fsm_debug("  Usage count: " . ($signal_info->{usage_count} || 'unknown'));
        }

        my $ast = $recovery_support->resolve_intermediate_signal_runtime_ast($signal_name, $signal_info);
        if ($ast && blessed($ast)) {
            fsm_debug("  Using runtime AST for filtering: " . ref($ast), 3)
                if $trace_signal_detail;
        } else {
            my $miss_reason = ($signal_info && ref($signal_info) eq 'HASH')
                ? ($signal_info->{runtime_ast_miss_reason} || 'unknown_runtime_ast_miss')
                : 'unknown_runtime_ast_miss';
            fsm_debug("  No runtime AST available - falling back to explicit runtime-AST-miss filtering ($miss_reason)", 3)
                if $trace_signal_detail;
        }

        my $should_filter = ($ast && blessed($ast))
            ? $filter_policy_support->should_filter_ast_based($ast, $signal_name, $signal_info)
            : $filter_policy_support->should_filter_runtime_ast_miss($signal_name, $signal_info);
        if ($should_filter) {
            $initially_filtered_signals{$signal_name} = $signal_info;
            fsm_debug("[ConsolidatedIntermediateClassificationSupport.pm][classify_consolidated_signals()] INITIAL FILTER: '$signal_name' = $expression", 3)
                if $trace_signal_detail;
        } else {
            $initially_kept_signals{$signal_name} = $signal_info;
            fsm_debug("[ConsolidatedIntermediateClassificationSupport.pm][classify_consolidated_signals()] INITIAL KEEP: '$signal_name' = $expression", 3)
                if $trace_signal_detail;
        }
    }

    return {
        initially_kept_signals => \%initially_kept_signals,
        initially_filtered_signals => \%initially_filtered_signals,
        initially_kept_count => scalar(keys %initially_kept_signals),
        initially_filtered_count => scalar(keys %initially_filtered_signals),
    };
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one consolidated-intermediate classification owner bound to a
specific C<FSM::HDL::FlattenedDT> backend context.

=head2 classify_consolidated_signals

Runs the initial AST-aware consolidated intermediate keep/filter
classification and returns the resulting first-pass kept and filtered sets.

=cut
