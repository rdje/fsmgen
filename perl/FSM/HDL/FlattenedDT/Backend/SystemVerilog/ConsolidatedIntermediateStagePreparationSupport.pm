package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStagePreparationSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStagePreparationSupport - Own live direct consolidated intermediate stage preparation

=head1 DESCRIPTION

Owns the bounded stage-preparation family for the older direct
generated-module SystemVerilog consolidated intermediate path. This package
centralizes:

=over 4

=item *

full prepared-block reconstruction for one direct backend context by composing
the extracted collection, planning, and prepared-block projection owners

=item *

the live prepared-block handoff consumed by the extracted stage-generation
owner plus the extracted rendering owner

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport>
keeps merged-signal collection, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePlanningSupport>
keeps plan composition, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePreparedBlockSupport>
keeps prepared block-contract projection, and this package now keeps the live
composition of those owners for the direct backend path. The older
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStageSupport>
now keeps the live stage-6 generation handoff that consumes this prepared
block, the older
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateRenderingSupport>
keeps the final prepared-block rendering step that now follows this owner in
the live direct backend stage, and the older
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateBlockSupport>
package survives only as a directly testable compatibility shell outside the
live backend path.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

=head2 new

Construct one consolidated-intermediate stage-preparation owner bound to a
specific C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[ConsolidatedIntermediateStagePreparationSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 prepare_consolidated_intermediate_block

Rebuild one prepared consolidated intermediate block handoff for one FSM
module by composing the extracted collection, planning, and prepared-block
projection owners.

=cut

sub prepare_consolidated_intermediate_block ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my $all_intermediate_signals = $ctx->{backend_sv_consolidated_intermediate_support}
        ->collect_consolidated_intermediate_signals($fsm_module);
    my $plan = $ctx->{backend_sv_consolidated_intermediate_planning_support}
        ->plan_consolidated_intermediate_signals($all_intermediate_signals);

    return $ctx->{backend_sv_consolidated_intermediate_prepared_block_support}
        ->build_prepared_consolidated_intermediate_block($all_intermediate_signals, $plan);
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one consolidated-intermediate stage-preparation owner bound to a
specific C<FSM::HDL::FlattenedDT> backend context.

=head2 prepare_consolidated_intermediate_block

Rebuilds one prepared consolidated intermediate block handoff for one FSM
module by composing the extracted collection, planning, and prepared-block
projection owners.

=cut
