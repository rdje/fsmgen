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

=cut

sub render_consolidated_intermediate_assignments ($self, $prepared_block) {
    my $ctx = $self->{flattened_dt};
    my $recovery_support = $ctx->{backend_sv_intermediate_recovery_support};
    my $filtered_signals = $prepared_block->{filtered_signals} || {};
    my $sorted_signals = $prepared_block->{sorted_signals} || [];
    my $hdl = "";

    for my $signal_name (@{$sorted_signals}) {
        my $signal_info = $filtered_signals->{$signal_name};
        my $source = $signal_info->{source};

        my $expression = $recovery_support->render_intermediate_signal_expression($signal_name, $signal_info);
        unless (defined($expression) && $expression ne '') {
            fsm_debug("CONSOL_INTER_SIG: WARNING - No renderable expression for $signal_name, skipping assign emission", 3);
            next;
        }

        $hdl .= "  assign $signal_name = $expression; // Source: $source\n";
        fsm_debug("  CONSOLIDATED: assign $signal_name = $expression (source: $source)", 3);
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
