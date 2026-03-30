package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateRenderingSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateRenderingSupport - Own live direct consolidated intermediate prepared-block rendering

=head1 DESCRIPTION

Owns the bounded prepared-block rendering family for the older direct
generated-module SystemVerilog consolidated intermediate path. This package
centralizes:

=over 4

=item *

final consolidated intermediate block rendering from an already prepared block
contract

=item *

composition of the extracted declaration and assignment owners over that
prepared contract

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStageSupport>
now owns the live stage-6 generation composition consumed by the direct
backend orchestrator, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStagePreparationSupport>
keeps live prepared-block reconstruction, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateDeclarationSupport>
keeps prepared wire-declaration rendering, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateAssignmentSupport>
keeps prepared assign rendering, and this package now keeps the live
prepared-block rendering composition for the direct backend path. The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateGenerationSupport>
now survives only as a compatibility wrapper outside the live backend path.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;

=head2 new

Construct one consolidated-intermediate rendering owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[ConsolidatedIntermediateRenderingSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 render_prepared_consolidated_intermediate_block

Render the consolidated direct-backend intermediate-signal block from the
prepared block contract produced by the extracted stage-preparation owner.

=cut

sub render_prepared_consolidated_intermediate_block ($self, $prepared_block) {
    my $ctx = $self->{flattened_dt};
    my $declaration_support = $ctx->{backend_sv_consolidated_intermediate_declaration_support};
    my $assignment_support = $ctx->{backend_sv_consolidated_intermediate_assignment_support};
    my $filtered_signals = $prepared_block->{filtered_signals} || {};
    my $hdl = "";

    # Step 4a: LHS signal declarations are emitted once in generate_internal_signal_declarations().
    # Avoid redeclaring them here with incompatible types.

    # Step 4b: Generate HDL for consolidated intermediate signals
    if (%{$filtered_signals}) {
        $hdl .= "  // Consolidated intermediate signals (AST factorization + pre-scan)\n";

        # First pass: Generate all wire declarations through the extracted owner
        $hdl .= $declaration_support->render_consolidated_intermediate_declarations($prepared_block);

        $hdl .= "\n";  # Add spacing between declarations and assignments

        # Second pass: Generate all assign statements through the extracted owner
        $hdl .= $assignment_support->render_consolidated_intermediate_assignments($prepared_block);

        $hdl .= "\n";
    } else {
        fsm_debug("  No consolidated intermediate signals needed after filtering", 3);
    }

    fsm_debug("*** CONSOLIDATED INTERMEDIATE SIGNAL GENERATION COMPLETE ***\n", 3);

    return $hdl;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one consolidated-intermediate rendering owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 render_prepared_consolidated_intermediate_block

Renders the consolidated direct-backend intermediate-signal block from the
prepared block contract produced by the extracted stage-preparation owner.

=cut
