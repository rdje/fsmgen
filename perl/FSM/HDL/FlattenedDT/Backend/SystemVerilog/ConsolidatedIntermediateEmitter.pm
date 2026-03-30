package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateEmitter;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateEmitter - Render direct consolidated intermediate-signal blocks

=head1 DESCRIPTION

This package now survives as a narrow compatibility shell outside the live
direct generated-module SystemVerilog backend path. It centralizes one
directly testable wrapper:

=over 4

=item *

rebuilding consolidated intermediate block rendering from an already prepared
block contract by delegating to the live generation owner when available

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateGenerationSupport>
now owns the live final prepared-block rendering family for the direct backend
path, while this package remains only as a compatibility surface for direct
owner tests.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;

=head2 new

Construct one consolidated-intermediate emitter bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[ConsolidatedIntermediateEmitter.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 render_consolidated_intermediate_block

Render the consolidated direct-backend intermediate-signal block from the
prepared block contract produced by the extracted block-preparation owner.

=cut

sub render_consolidated_intermediate_block ($self, $prepared_block) {
    my $ctx = $self->{flattened_dt};
    my $generation_support = $ctx->{backend_sv_consolidated_intermediate_generation_support};

    if ($generation_support
        && $generation_support->can('render_prepared_consolidated_intermediate_block')) {
        return $generation_support->render_prepared_consolidated_intermediate_block($prepared_block);
    }

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

Constructs one consolidated-intermediate emitter bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 render_consolidated_intermediate_block

Renders the consolidated direct-backend intermediate-signal block from the
prepared block contract produced by the extracted block-preparation owner.

=cut
