package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateGenerationSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateGenerationSupport - Compatibility shell for direct consolidated intermediate stage generation

=head1 DESCRIPTION

This package now survives as a narrow compatibility shell outside the live
direct generated-module SystemVerilog backend path. It centralizes one
directly testable wrapper:

=over 4

=item *

rebuilding the full consolidated intermediate block from one FSM module by
delegating to the extracted stage-preparation and rendering owners

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStagePreparationSupport>
now keeps live prepared-block reconstruction over the extracted collection,
planning, and prepared-block projection owners, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateRenderingSupport>
now keeps final prepared-block rendering over the extracted declaration and
assignment owners, the narrowed
C<FSM::HDL::FlattenedDT::Orchestrator> now composes those two owners directly
during live backend generation, and the older
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

=head2 new

Construct one consolidated-intermediate generation wrapper bound to a specific
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

Rebuild the full consolidated intermediate HDL block for one FSM module by
delegating to the extracted stage-preparation and rendering owners.

=cut

sub generate_consolidated_intermediate_block ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my $prepared_block = $ctx->{backend_sv_consolidated_intermediate_stage_preparation_support}
        ->prepare_consolidated_intermediate_block($fsm_module);

    return $ctx->{backend_sv_consolidated_intermediate_rendering_support}
        ->render_prepared_consolidated_intermediate_block($prepared_block);
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one consolidated-intermediate generation wrapper bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 generate_consolidated_intermediate_block

Rebuilds the full consolidated intermediate HDL block for one FSM module by
delegating to the extracted stage-preparation and rendering owners.

=cut
