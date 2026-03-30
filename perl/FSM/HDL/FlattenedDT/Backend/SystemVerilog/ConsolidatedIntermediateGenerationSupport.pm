package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateGenerationSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateGenerationSupport - Own direct consolidated intermediate stage generation

=head1 DESCRIPTION

Owns the bounded stage-generation family for the older direct generated-module
SystemVerilog consolidated intermediate path. This package centralizes:

=over 4

=item *

final consolidated intermediate block rendering from that prepared contract

=item *

the full stage handoff consumed by the narrowed
C<FSM::HDL::FlattenedDT::Orchestrator>

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStagePreparationSupport>
now keeps live prepared-block reconstruction over the extracted collection,
planning, and prepared-block projection owners, this package keeps final
prepared-block rendering over the extracted declaration and assignment owners,
and the older
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateEmitter>
package now survives only as a directly testable compatibility shell outside
the live backend path.
The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateBlockSupport>
also survives only as a directly testable compatibility shell outside the
live backend path.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;

=head2 new

Construct one consolidated-intermediate stage owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[ConsolidatedIntermediateGenerationSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 generate_consolidated_intermediate_block

Generate the full consolidated intermediate HDL block for one FSM module by
composing the extracted live stage-preparation owner plus final prepared-block
rendering directly.

=cut

=head2 render_prepared_consolidated_intermediate_block

Render the consolidated direct-backend intermediate-signal block from the
prepared block contract produced by the extracted block-preparation owner.

=cut

sub generate_consolidated_intermediate_block ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my $prepared_block = $ctx->{backend_sv_consolidated_intermediate_stage_preparation_support}
        ->prepare_consolidated_intermediate_block($fsm_module);

    return $self->render_prepared_consolidated_intermediate_block($prepared_block);
}

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

Constructs one consolidated-intermediate stage owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 generate_consolidated_intermediate_block

Generates the full consolidated intermediate HDL block for one FSM module by
composing the extracted live stage-preparation owner plus final prepared-block
rendering directly.

=head2 render_prepared_consolidated_intermediate_block

Renders the consolidated direct-backend intermediate-signal block from the
prepared block contract produced by the extracted block-preparation owner.

=cut
