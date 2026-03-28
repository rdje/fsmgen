package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSelectionSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSelectionSupport - Own dependency-aware consolidated intermediate keep/filter/rescue selection

=head1 DESCRIPTION

Owns the bounded selection family for the older direct generated-module
SystemVerilog consolidated intermediate path. This package centralizes:

=over 4

=item *

per-signal rendered-expression lookup before selection

=item *

direct AST-first keep/filter dispatch over the extracted recovery and
filter-policy owners

=item *

dependency-aware rescue of filtered intermediates required by kept signals

=item *

selection summary metadata for the final kept and filtered sets

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePlanningSupport>
now owns dependency-map construction, dependency-safe ordering, and overall plan
composition, while this package owns the narrower “which consolidated
intermediates survive?” selection side of the direct backend path.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;
use Scalar::Util qw(blessed);

=head2 new

Construct one consolidated-intermediate selection owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[ConsolidatedIntermediateSelectionSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 filter_consolidated_signals

Apply the dependency-aware consolidated-intermediate keep/filter/rescue plan
and return the resulting filtered set plus intermediate selection metadata.

=cut

sub filter_consolidated_signals ($self, $all_intermediate_signals, $signal_dependencies) {
    my $ctx = $self->{flattened_dt};
    my $recovery_support = $ctx->{backend_sv_intermediate_recovery_support};
    my $filter_policy_support = $ctx->{backend_sv_intermediate_filter_policy_support};
    my %initially_filtered_signals;
    my %initially_kept_signals;
    my %rescued_signals;

    for my $signal_name (keys %{ $all_intermediate_signals || {} }) {
        my $signal_info = $all_intermediate_signals->{$signal_name};
        my $expression = $recovery_support->render_intermediate_signal_expression($signal_name, $signal_info);
        next unless defined($expression) && $expression ne '';

        fsm_debug("\n*** AST_FILTER_CHECK: Analyzing signal '$signal_name' ***", 3);
        fsm_debug("  Expression: '$expression'", 3);
        fsm_debug("  Source: $signal_info->{source}", 3);
        fsm_debug("  Usage count: " . ($signal_info->{usage_count} || 'unknown'));

        my $ast = $recovery_support->resolve_intermediate_signal_runtime_ast($signal_name, $signal_info);
        if ($ast && blessed($ast)) {
            fsm_debug("  Using runtime AST for filtering: " . ref($ast), 3);
        } else {
            my $miss_reason = ($signal_info && ref($signal_info) eq 'HASH')
                ? ($signal_info->{runtime_ast_miss_reason} || 'unknown_runtime_ast_miss')
                : 'unknown_runtime_ast_miss';
            fsm_debug("  No runtime AST available - falling back to explicit runtime-AST-miss filtering ($miss_reason)", 3);
        }

        my $should_filter = ($ast && blessed($ast))
            ? $filter_policy_support->should_filter_ast_based($ast, $signal_name, $signal_info)
            : $filter_policy_support->should_filter_runtime_ast_miss($signal_name, $signal_info);
        if ($should_filter) {
            $initially_filtered_signals{$signal_name} = $signal_info;
            fsm_debug("[ConsolidatedIntermediateSelectionSupport.pm][filter_consolidated_signals()] INITIAL FILTER: '$signal_name' = $expression", 3);
        } else {
            $initially_kept_signals{$signal_name} = $signal_info;
            fsm_debug("[ConsolidatedIntermediateSelectionSupport.pm][filter_consolidated_signals()] INITIAL KEEP: '$signal_name' = $expression", 3);
        }
    }

    for my $kept_signal (keys %initially_kept_signals) {
        next unless $signal_dependencies->{$kept_signal};
        for my $dependency (@{ $signal_dependencies->{$kept_signal} }) {
            if ($initially_filtered_signals{$dependency}) {
                $rescued_signals{$dependency} = $initially_filtered_signals{$dependency};
                fsm_debug("[ConsolidatedIntermediateSelectionSupport.pm][filter_consolidated_signals()] RESCUED: '$dependency' is needed by '$kept_signal'", 3);
            }
        }
    }

    my %filtered_signals = (%initially_kept_signals, %rescued_signals);
    my %finally_filtered_signals = %initially_filtered_signals;
    delete @finally_filtered_signals{keys %rescued_signals};

    my $initially_kept_count = scalar(keys %initially_kept_signals);
    my $rescued_count = scalar(keys %rescued_signals);
    my $filtered_count = scalar(keys %finally_filtered_signals);
    my $total_kept = scalar(keys %filtered_signals);

    fsm_debug("[ConsolidatedIntermediateSelectionSupport.pm][filter_consolidated_signals()] Summary: initially_kept=$initially_kept_count rescued=$rescued_count filtered=$filtered_count total_kept=$total_kept", 3);

    return {
        filtered_signals => \%filtered_signals,
        initially_kept_signals => \%initially_kept_signals,
        initially_filtered_signals => \%initially_filtered_signals,
        rescued_signals => \%rescued_signals,
        finally_filtered_signals => \%finally_filtered_signals,
        initially_kept_count => $initially_kept_count,
        rescued_count => $rescued_count,
        filtered_count => $filtered_count,
        total_kept_count => $total_kept,
    };
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one consolidated-intermediate selection owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 filter_consolidated_signals

Applies the dependency-aware consolidated-intermediate keep/filter/rescue plan
and returns the resulting filtered set plus intermediate selection metadata.
This owner now performs the live AST-first filter dispatch itself by combining
the extracted recovery and filter-policy owners directly.

=cut
