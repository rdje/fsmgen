package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateEmitter;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateEmitter - Render direct consolidated intermediate-signal blocks

=head1 DESCRIPTION

Owns the bounded consolidated intermediate-signal emission family for the older
direct generated-module SystemVerilog backend. This package takes the prepared
consolidated intermediate block contract and renders the consolidated wire and
assign block that appears before unified WEN/EN signal generation.

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
    my $recovery_support = $ctx->{backend_sv_intermediate_recovery_support};
    my $width_support = $ctx->{backend_sv_intermediate_width_support};
    my $filtered_signals = $prepared_block->{filtered_signals} || {};
    my $sorted_signals = $prepared_block->{sorted_signals} || [];
    my $hdl = "";

    # Step 4a: LHS signal declarations are emitted once in generate_internal_signal_declarations().
    # Avoid redeclaring them here with incompatible types.

    # Step 4b: Generate HDL for consolidated intermediate signals
    if (%{$filtered_signals}) {
        $hdl .= "  // Consolidated intermediate signals (AST factorization + pre-scan)\n";

        # First pass: Generate all wire declarations
        for my $signal_name (@{$sorted_signals}) {
            my $signal_info = $filtered_signals->{$signal_name};
            my $width = $width_support->resolve_intermediate_signal_width($signal_name, $signal_info, $filtered_signals);

            # Generate wire declaration
            if ($width > 1) {
                $hdl .= "  wire [" . ($width - 1) . ":0] $signal_name;\n";
            } else {
                $hdl .= "  wire $signal_name;\n";
            }
        }

        $hdl .= "\n";  # Add spacing between declarations and assignments

        # Second pass: Generate all assign statements
        for my $signal_name (@{$sorted_signals}) {
            my $signal_info = $filtered_signals->{$signal_name};
            my $source = $signal_info->{source};

            my $expression = $recovery_support->render_intermediate_signal_expression($signal_name, $signal_info);
            unless (defined($expression) && $expression ne '') {
                fsm_debug("CONSOL_INTER_SIG: WARNING - No renderable expression for $signal_name, skipping assign emission", 3);
                next;
            }

            $hdl .= "  assign $signal_name = $expression; // Source: $source\n";

            fsm_debug("  CONSOLIDATED: wire $signal_name = $expression (source: $source)", 3);
        }

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
