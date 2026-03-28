package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateBlockSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateBlockSupport - Own direct consolidated intermediate block preparation

=head1 DESCRIPTION

Owns the bounded preparation family for the older direct generated-module
SystemVerilog consolidated intermediate block. This package centralizes:

=over 4

=item *

collection of the normalized consolidated intermediate-signal set for one
prepared backend context

=item *

planning handoff into the extracted dependency-aware rescue/filter/order owner

=item *

projection of the prepared block contract consumed by the narrowed emitter

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport>
keeps collection and normalization, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePlanningSupport>
keeps dependency-aware planning, and the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateEmitter>
now narrows to final HDL rendering from the prepared block contract.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;

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

Prepare the normalized consolidated intermediate block contract for one FSM
module by composing the extracted collection and planning owners.

=cut

sub prepare_consolidated_intermediate_block ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my $all_intermediate_signals = $ctx->{backend_sv_consolidated_intermediate_support}
        ->collect_consolidated_intermediate_signals($fsm_module);
    my $plan = $ctx->{backend_sv_consolidated_intermediate_planning_support}
        ->plan_consolidated_intermediate_signals($all_intermediate_signals);

    fsm_debug(
        "[ConsolidatedIntermediateBlockSupport.pm][prepare_consolidated_intermediate_block()] Prepared consolidated block: total_signals="
          . scalar(keys %{ $all_intermediate_signals || {} })
          . ", kept="
          . ($plan->{total_kept_count} || 0)
          . ", ordered="
          . scalar(@{ $plan->{sorted_signals} || [] }),
        3,
    );

    return {
        all_intermediate_signals => $all_intermediate_signals,
        %{$plan},
    };
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one consolidated-intermediate block owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 prepare_consolidated_intermediate_block

Prepares the normalized consolidated intermediate block contract for one FSM
module by composing the extracted collection and planning owners.

=cut
