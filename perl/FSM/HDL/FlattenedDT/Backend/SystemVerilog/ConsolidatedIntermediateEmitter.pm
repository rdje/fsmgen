package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateEmitter;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateEmitter - Render direct consolidated intermediate-signal blocks

=head1 DESCRIPTION

Owns the bounded consolidated intermediate block-emission family for the older
direct generated-module SystemVerilog backend. This package takes the prepared
consolidated intermediate block contract and renders the consolidated block
shell: comment header, spacing, and the handoff over the extracted declaration
and assignment rendering owners before unified WEN/EN signal generation.

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
