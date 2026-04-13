package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStageSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStageSupport - Own live direct consolidated intermediate stage generation

=head1 DESCRIPTION

Owns the bounded live stage-generation family for the older direct
generated-module SystemVerilog consolidated intermediate path. This package
centralizes:

=over 4

=item *

full consolidated intermediate block generation for one FSM module by
composing the extracted stage-preparation, pre-generation validation, and
rendering owners

=item *

the live stage-6 handoff consumed directly by the narrowed
C<FSM::HDL::FlattenedDT::Orchestrator>

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStagePreparationSupport>
keeps live prepared-block reconstruction over the extracted collection,
planning, and prepared-block projection owners, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateRenderingSupport>
keeps final prepared-block rendering over the extracted declaration and
assignment owners, the paired operand-contract validator keeps the
pre-generation AST/declaration/assignment safety checks, and this package now
keeps the live composition of those owners for the direct backend path. The older
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateGenerationSupport>
package survives only as a directly testable compatibility shell outside the
live backend path.

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
      or die "[ConsolidatedIntermediateStageSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 generate_consolidated_intermediate_block

Generate the full consolidated intermediate HDL block for one FSM module by
composing the extracted stage-preparation and rendering owners.

=cut

sub generate_consolidated_intermediate_block ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my $prepared_block = $ctx->{backend_sv_consolidated_intermediate_stage_preparation_support}
        ->prepare_consolidated_intermediate_block($fsm_module);
    $ctx->{backend_sv_operand_contract_validation_support}
        ->validate_pre_generation_operand_contract($fsm_module, $prepared_block);

    return $ctx->{backend_sv_consolidated_intermediate_rendering_support}
        ->render_prepared_consolidated_intermediate_block($prepared_block);
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one consolidated-intermediate stage owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 generate_consolidated_intermediate_block

Generates the full consolidated intermediate HDL block for one FSM module by
composing the extracted stage-preparation, pre-generation validation, and
rendering owners.

=cut
