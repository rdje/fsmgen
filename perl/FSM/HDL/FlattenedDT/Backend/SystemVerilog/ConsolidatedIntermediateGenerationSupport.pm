package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateGenerationSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateGenerationSupport - Own direct consolidated intermediate stage generation

=head1 DESCRIPTION

Owns the bounded stage-generation family for the older direct generated-module
SystemVerilog consolidated intermediate path. This package centralizes:

=over 4

=item *

full prepared-block generation for one direct backend context by composing the
extracted collection, planning, and prepared-block projection owners

=item *

final consolidated intermediate block rendering from that prepared contract

=item *

the full stage handoff consumed by the narrowed
C<FSM::HDL::FlattenedDT::Orchestrator>

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport>
keeps merged-signal collection, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePlanningSupport>
keeps plan composition, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePreparedBlockSupport>
keeps prepared block-contract projection, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateEmitter>
keeps final block composition, and the older
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateBlockSupport>
package now survives only as a directly testable compatibility shell outside
the live backend path.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

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
composing the extracted collection, planning, prepared-block projection, and
final emitter owners directly.

=cut

sub generate_consolidated_intermediate_block ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my $all_intermediate_signals = $ctx->{backend_sv_consolidated_intermediate_support}
        ->collect_consolidated_intermediate_signals($fsm_module);
    my $plan = $ctx->{backend_sv_consolidated_intermediate_planning_support}
        ->plan_consolidated_intermediate_signals($all_intermediate_signals);
    my $prepared_block = $ctx->{backend_sv_consolidated_intermediate_prepared_block_support}
        ->build_prepared_consolidated_intermediate_block($all_intermediate_signals, $plan);

    return $ctx->{backend_sv_consolidated_intermediate}
        ->render_consolidated_intermediate_block($prepared_block);
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one consolidated-intermediate stage owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 generate_consolidated_intermediate_block

Generates the full consolidated intermediate HDL block for one FSM module by
composing the extracted collection, planning, prepared-block projection, and
final emitter owners directly.

=cut
