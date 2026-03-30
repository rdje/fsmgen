package FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPipelineSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPipelineSupport - Own live post-flattening direct SystemVerilog assembly

=head1 DESCRIPTION

Owns the bounded live post-flattening generation-pipeline family for the
older direct generated-module SystemVerilog backend path. This package
centralizes:

=over 4

=item *

full step-2-through-step-7 SystemVerilog assembly once the decision trees
have already been flattened

=item *

the live composition of scaffold emission, declaration emission, enable
generation, factorization-policy preparation, consolidated intermediate stage
generation, unified WEN/EN emission, assignment emission, and module closeout

=back

The paired
C<FSM::HDL::FlattenedDT::Orchestrator> now keeps per-run reset, FSM-module
attachment, and decision-tree flattening, while this package keeps the live
direct backend text-assembly sequence that follows those phases.

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

Generate the full direct SystemVerilog module body and closeout from the
already flattened backend state.

=cut

sub generate_systemverilog_module ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};

    # Step 2: Generate SystemVerilog with enable-based methodology
    my $hdl = $ctx->{backend_sv_scaffold}->generate_header($fsm_module);
    $hdl .= $ctx->{backend_sv_scaffold}->generate_module_declaration($fsm_module);
    $hdl .= $ctx->{backend_sv_scaffold}->generate_state_encoding($fsm_module);
    $hdl .= $ctx->{backend_sv_scaffold}->generate_state_register($fsm_module);
    $hdl .= $ctx->{backend_sv_internal_decl}->generate_internal_signal_declarations($fsm_module);
    fsm_debug("Step 2 - Basic HDL structure generated", 3);

    # Step 3: Generate enable conditions FIRST (this will track intermediate signal requirements)
    $hdl .= $ctx->{enable_graph_enable_support}->generate_enable_conditions($fsm_module);
    fsm_debug("Step 3 - Enable conditions generated", 3);

    # TIMING FIX: Count logical operations BEFORE any intermediate signal creation!
    fsm_debug("\n*** TIMING FIX: Running logical operation counting BEFORE pre-scan ***", 3);
    $ctx->{enable_graph_factorization_policy_support}->count_binary_logical_operation_occurrences();
    fsm_debug("Step 4 - Logical operation counting completed (BEFORE pre-scan!)", 3);

    # Step 5: PRE-SCAN all WEN/EN expressions to identify needed intermediate signals (now with counts available)
    $ctx->{enable_graph_enable_support}->prescan_wen_en_for_intermediate_signals();
    fsm_debug("Step 5 - PRE-SCAN completed (AFTER logical operation counting!)", 3);

    # Step 6: Generate consolidated intermediate signals (combining AST factorization + pre-scan)
    $hdl .= $ctx->{backend_sv_consolidated_intermediate_stage_support}
        ->generate_consolidated_intermediate_block($fsm_module);
    fsm_debug("Step 6 - Consolidated intermediate signals generated", 3);

    # Step 7: Generate WEN/EN signals (using pre-declared intermediate signals)
    $hdl .= $ctx->{enable_graph_enable_support}->generate_unified_wen_en_signals($fsm_module);
    fsm_debug("Step 7 - WEN/EN signals generated", 3);

    $hdl .= $ctx->{enable_graph_assignment_support}->generate_signal_assignments($fsm_module);
    $hdl .= "endmodule\n";

    return $hdl;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one SystemVerilog generation-pipeline owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 generate_systemverilog_module

Generates the full direct SystemVerilog module body and closeout from the
already flattened backend state.

=cut
