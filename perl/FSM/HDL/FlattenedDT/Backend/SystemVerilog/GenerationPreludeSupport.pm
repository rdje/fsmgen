package FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPreludeSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPreludeSupport - Own live pre-stage direct SystemVerilog generation prelude

=head1 DESCRIPTION

Owns the bounded live generation-prelude family for the older direct
generated-module SystemVerilog backend path. This package centralizes:

=over 4

=item *

full pre-stage HDL assembly before consolidated intermediate generation

=item *

the live composition of scaffold emission, declaration emission, enable
generation, factorization-policy preparation, and WEN/EN prescan

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPipelineSupport>
now keeps the broader post-flattening module assembly sequence, but this
package owns the prefix that must be established before the consolidated
intermediate stage can run.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;

=head2 new

Construct one SystemVerilog generation-prelude owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[GenerationPreludeSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 generate_systemverilog_prelude

Generate the direct SystemVerilog HDL prefix and prepare the backend state
that must exist before consolidated intermediate generation can run.

=cut

sub generate_systemverilog_prelude ($self, $fsm_module) {
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

    return $hdl;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one SystemVerilog generation-prelude owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 generate_systemverilog_prelude

Generates the direct SystemVerilog HDL prefix and prepares the backend state
that must exist before consolidated intermediate generation can run.

=cut
