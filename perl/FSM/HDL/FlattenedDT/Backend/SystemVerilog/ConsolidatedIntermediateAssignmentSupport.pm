package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateAssignmentSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateAssignmentSupport - Render direct consolidated intermediate assignments

=head1 DESCRIPTION

Owns the bounded consolidated intermediate assignment-rendering family for the
older direct generated-module SystemVerilog backend. This package centralizes:

=over 4

=item *

rendered-expression recovery for prepared consolidated intermediate signals

=item *

final assign-statement emission for the prepared consolidated intermediate set

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateEmitter>
now narrows further to block composition and wire declaration rendering, while
this package owns the assign emission half of that prepared block contract.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;
use Carp qw(confess);
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport;

=head2 new

Construct one consolidated-intermediate assignment owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[ConsolidatedIntermediateAssignmentSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 render_consolidated_intermediate_assignments

Render the assign statements for the prepared consolidated intermediate block,
skipping any signal that cannot currently be rendered back to SystemVerilog
text.
Captured binary events publish separate bitwise/arithmetic syntactic origins
and query the corresponding optional current-policy publisher.
Only agreeing completed source/factorizer allocation proof adds width_allocation;
separate optional source-tree methods add complete source_tree_origin and
source_tree_width_allocation fields only for agreeing actual selected trees and
current completed source policy. Legacy providers without these methods retain
their event shape. These fields do not change assignment text or admit ranges.
The separate optional graph publisher adds graph_width_allocation only for a
current selected arithmetic graph with plain transitive source/result profiles.
HDL text and symbolic range admission are unchanged.

Literal helpers additionally require their same selected declaration expression
and record the exact emitted expression in a separate generation-local ledger.
Complete physical target proof compares both ledgers before HDL returns.

=cut

sub render_consolidated_intermediate_assignments ($self, $prepared_block) {
    my $ctx = $self->{flattened_dt};
    my $recovery_support = $ctx->{backend_sv_intermediate_recovery_support};
    my $filtered_signals = $prepared_block->{filtered_signals} || {};
    my $sorted_signals = $prepared_block->{sorted_signals} || [];
    my $trace_signal_detail = debug_enabled() && debug_level() >= 3;
    my $hdl = "";

    for my $signal_name (@{$sorted_signals}) {
        my $signal_info = $filtered_signals->{$signal_name};
        my $source = $signal_info->{source};
        $source = 'derived_expression'
            unless defined($source) && length($source);

        my $expression = $recovery_support->render_intermediate_signal_expression($signal_name, $signal_info);
        if (FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport
            ->requires_emission($ctx->{fsm_module}{signals}{$signal_name}, $filtered_signals)) {
            my $declaration = $ctx->{direct_declared_width_emitted_literal_ranges}{$signal_name};
            confess "Direct literal assignment requires its same selected declaration expression\n"
                unless $declaration && defined($expression) && $expression eq $declaration->{expression};
            $ctx->{direct_declared_width_emitted_literal_assignments}{$signal_name} = $expression;
        }
        unless (defined($expression) && $expression ne '') {
            fsm_warn("CONSOL_INTER_SIG: No renderable expression for $signal_name, skipping assign emission");
            next;
        }

        $hdl .= "  assign $signal_name = $expression; // Source: $source\n";
        if (my $capture = $ctx->{declared_width_declaration_capture}) {
            my $origin = $recovery_support->scalar_reduction_origin($signal_name, $signal_info, $expression);
            my $bitwise = $recovery_support->binary_bitwise_origin($signal_name, $signal_info, $expression);
            my $arithmetic = $recovery_support->can('binary_arithmetic_origin')
                ? $recovery_support->binary_arithmetic_origin($signal_name, $signal_info, $expression) : undef;
            my $allocation = $bitwise && $recovery_support->can('binary_width_allocation')
                ? $recovery_support->binary_width_allocation($signal_name, $signal_info, $expression)
                : $arithmetic && $recovery_support->can('arithmetic_width_allocation')
                    ? $recovery_support->arithmetic_width_allocation($signal_name, $signal_info, $expression) : undef;
            my $graph_allocation = !$allocation && $arithmetic && $recovery_support->can('arithmetic_graph_width_allocation')
                ? $recovery_support->arithmetic_graph_width_allocation($signal_name, $signal_info, $expression) : undef;
            my $source_tree = $recovery_support->can('source_bitwise_tree_origin')
                ? $recovery_support->source_bitwise_tree_origin($signal_name, $signal_info, $expression) : undef;
            my $source_tree_policy = $source_tree && $recovery_support->can('source_bitwise_tree_width_allocation')
                ? $recovery_support->source_bitwise_tree_width_allocation($signal_name, $signal_info, $expression) : undef;
            $capture->record_intermediate_assignment($signal_name,
                {expression => $expression, ($origin ? (reduction_origin => $origin) : ()),
                    ($bitwise ? (bitwise_origin => $bitwise) : ()),
                    ($arithmetic ? (arithmetic_origin => $arithmetic) : ()),
                    ($allocation ? (width_allocation => $allocation) : ()),
                    ($graph_allocation ? (graph_width_allocation => $graph_allocation) : ()),
                    ($source_tree ? (source_tree_origin => $source_tree) : ()),
                    ($source_tree_policy ? (source_tree_width_allocation => $source_tree_policy) : ())});
        }
        fsm_debug("  CONSOLIDATED: assign $signal_name = $expression (source: $source)", 3)
            if $trace_signal_detail;
    }

    return $hdl;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one consolidated-intermediate assignment owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 render_consolidated_intermediate_assignments

Renders the assign statements for the prepared consolidated intermediate
block, skipping any signal that cannot currently be rendered back to
SystemVerilog text.

=cut
