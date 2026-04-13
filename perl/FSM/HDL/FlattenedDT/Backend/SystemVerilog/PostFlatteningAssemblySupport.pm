package FSM::HDL::FlattenedDT::Backend::SystemVerilog::PostFlatteningAssemblySupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::PostFlatteningAssemblySupport - Own live post-flattening direct SystemVerilog assembly

=head1 DESCRIPTION

Owns the bounded live post-flattening module-assembly family for the older
direct generated-module SystemVerilog backend path. This package centralizes:

=over 4

=item *

full direct SystemVerilog module assembly after decision-tree flattening

=item *

composition of scaffold emission, internal declaration emission,
enable-condition emission, the prescan-aware consolidated intermediate stage,
and post-stage tail closeout

=back

The paired C<FSM::HDL::FlattenedDT::Orchestrator> now owns per-run reset,
FSM-module attachment, decision-tree flattening, and the final handoff to this
owner. The older
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPipelineSupport>
package survives only as a directly testable compatibility shell over this
live owner.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;

=head2 new

Construct one post-flattening SystemVerilog assembly owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[PostFlatteningAssemblySupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 generate_systemverilog_module

Generate the full direct SystemVerilog module after decision-tree flattening.

=cut

sub generate_systemverilog_module ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my $consolidated_intermediate_hdl = $ctx->{backend_sv_consolidated_intermediate_stage_support}
        ->generate_consolidated_intermediate_block($fsm_module);

    my $hdl = $ctx->{backend_sv_scaffold}->generate_header($fsm_module);
    $hdl .= $ctx->{backend_sv_scaffold}->generate_module_declaration($fsm_module);
    $hdl .= $ctx->{backend_sv_scaffold}->generate_state_encoding($fsm_module);
    $hdl .= $ctx->{backend_sv_scaffold}->generate_state_register($fsm_module);
    $hdl .= $ctx->{backend_sv_internal_decl}->generate_internal_signal_declarations($fsm_module);
    fsm_debug("Step 2 - Basic HDL structure generated", 3);
    $hdl .= $ctx->{enable_graph_enable_support}->generate_enable_conditions($fsm_module);
    fsm_debug("Step 3 - Enable conditions generated", 3);

    $hdl .= $consolidated_intermediate_hdl;
    fsm_debug("Step 6 - Consolidated intermediate signals generated", 3);

    $hdl .= $ctx->{backend_sv_generation_tail_support}
        ->generate_systemverilog_tail($fsm_module);

    return $hdl;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one post-flattening SystemVerilog assembly owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 generate_systemverilog_module

Generates the full direct SystemVerilog module after decision-tree flattening.

=cut
