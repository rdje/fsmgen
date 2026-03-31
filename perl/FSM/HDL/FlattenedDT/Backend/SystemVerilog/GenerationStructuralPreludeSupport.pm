package FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationStructuralPreludeSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationStructuralPreludeSupport - Compatibility shell for direct SystemVerilog structural prelude assembly

=head1 DESCRIPTION

Keeps a directly testable compatibility shell for the older direct
generated-module SystemVerilog backend path. This package centralizes:

=over 4

=item *

the structural HDL prefix that must be emitted before enable-oriented
preparation can run

=item *

compatibility composition of scaffold rendering and internal declaration
rendering for one direct backend module body

=back

The paired C<FSM::HDL::FlattenedDT::Orchestrator> now reaches the scaffold and
internal-declaration owners directly in the live backend path, so this
package survives as a compatibility shell outside that live path. The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPreludeSupport>
likewise rebuilds its compatibility prelude directly over those same live
owners.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;

=head2 new

Construct one SystemVerilog structural-prelude owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[GenerationStructuralPreludeSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 generate_structural_prelude

Rebuild the direct SystemVerilog structural prefix by delegating to the live
scaffold and internal-declaration owners.

=cut

sub generate_structural_prelude ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};

    my $hdl = $ctx->{backend_sv_scaffold}->generate_header($fsm_module);
    $hdl .= $ctx->{backend_sv_scaffold}->generate_module_declaration($fsm_module);
    $hdl .= $ctx->{backend_sv_scaffold}->generate_state_encoding($fsm_module);
    $hdl .= $ctx->{backend_sv_scaffold}->generate_state_register($fsm_module);
    $hdl .= $ctx->{backend_sv_internal_decl}->generate_internal_signal_declarations($fsm_module);
    fsm_debug("Step 2 - Basic HDL structure generated", 3);

    return $hdl;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one SystemVerilog structural-prelude owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 generate_structural_prelude

Rebuilds the direct SystemVerilog structural prefix by delegating to the live
scaffold and internal-declaration owners.

=cut
