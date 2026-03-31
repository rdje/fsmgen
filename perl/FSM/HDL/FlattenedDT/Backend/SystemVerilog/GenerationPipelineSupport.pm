package FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPipelineSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPipelineSupport - Compatibility shell for post-flattening direct SystemVerilog assembly

=head1 DESCRIPTION

Keeps a directly testable compatibility shell for the older direct
generated-module SystemVerilog backend path. This package centralizes:

=over 4

=item *

full post-flattening direct SystemVerilog assembly once the decision trees
have already been flattened and the direct backend prelude has been
established

=item *

compatibility composition of structural-prelude generation, enable-oriented
preparation, consolidated intermediate stage generation, and the extracted
generation-tail owner

=back

The paired C<FSM::HDL::FlattenedDT::Orchestrator> now keeps per-run reset,
FSM-module attachment, decision-tree flattening, and live post-flattening
generation composition, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationStructuralPreludeSupport>
keeps structural scaffold/internal-declaration preparation, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationEnablePreparationSupport>
keeps enable-condition emission plus the extracted prescan-preparation owner,
the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationTailSupport>
keeps post-stage WEN/EN/assignment/module closeout, and this package now
survives only as a compatibility shell outside that live backend path.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;

=head2 new

Construct one SystemVerilog generation-pipeline owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[GenerationPipelineSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 generate_systemverilog_module

Rebuild the full direct SystemVerilog module body and closeout by
delegating to the extracted live owners.

=cut

sub generate_systemverilog_module ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};

    my $hdl = $ctx->{backend_sv_generation_structural_prelude_support}
        ->generate_structural_prelude($fsm_module);
    $hdl .= $ctx->{backend_sv_generation_enable_preparation_support}
        ->generate_enable_preparation($fsm_module);

    # Step 6: Generate consolidated intermediate signals (combining AST factorization + pre-scan)
    $hdl .= $ctx->{backend_sv_consolidated_intermediate_stage_support}
        ->generate_consolidated_intermediate_block($fsm_module);
    fsm_debug("Step 6 - Consolidated intermediate signals generated", 3);

    $hdl .= $ctx->{backend_sv_generation_tail_support}
        ->generate_systemverilog_tail($fsm_module);

    return $hdl;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one SystemVerilog generation-pipeline owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 generate_systemverilog_module

Rebuilds the full direct SystemVerilog module body and closeout by
delegating to the extracted live owners.

=cut
