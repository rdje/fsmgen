package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateBlockSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateBlockSupport - Compatibility shell for direct consolidated intermediate block preparation

=head1 DESCRIPTION

This package now survives as a narrow compatibility shell outside the live
direct generated-module SystemVerilog backend path. It centralizes one
directly testable wrapper:

=over 4

=item *

rebuilding the prepared consolidated block handoff by delegating to the live
stage-preparation owner

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport>
keeps collection and merge, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport>
keeps runtime metadata normalization, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePlanningSupport>
keeps dependency-aware planning, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePreparedBlockSupport>
keeps prepared block-contract projection, the live
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStagePreparationSupport>
package now composes those real owners directly, this package delegates to
that live owner, and the narrowed
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateGenerationSupport>
package now consumes that live prepared-block handoff instead of routing
through this shell during normal backend generation.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

=head2 new

Construct one consolidated-intermediate block owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[ConsolidatedIntermediateBlockSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 prepare_consolidated_intermediate_block

Rebuild one prepared consolidated intermediate block handoff for one FSM
module by composing the extracted collection, planning, and prepared-block
owners.

=cut

sub prepare_consolidated_intermediate_block ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};

    return $ctx->{backend_sv_consolidated_intermediate_stage_preparation_support}
        ->prepare_consolidated_intermediate_block($fsm_module);
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one consolidated-intermediate block owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 prepare_consolidated_intermediate_block

Rebuilds one prepared consolidated intermediate block handoff for one FSM
module by composing the extracted collection, planning, and prepared-block
owners.

=cut
