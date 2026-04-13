package FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPreludeSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPreludeSupport - Compatibility shell for direct SystemVerilog pre-stage generation prelude

=head1 DESCRIPTION

Keeps a directly testable compatibility shell for the older direct
generated-module SystemVerilog backend path. This package centralizes:

=over 4

=item *

full pre-stage HDL assembly before consolidated intermediate generation

=item *

compatibility composition of the extracted structural-prelude owner plus
direct enable-condition emission and the extracted prescan-preparation owner

=back

The paired C<FSM::HDL::FlattenedDT::Orchestrator> now reaches the live
scaffold/internal-declaration owners directly in the live backend path, while
the live consolidated-intermediate stage owner reaches the prescan owner
before prepared-block reconstruction. This package survives as a compatibility
shell outside that live path. The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPrescanPreparationSupport>
now keeps idempotent logical-operation counting plus WEN/EN prescan over the
direct backend state.

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

Rebuild the direct SystemVerilog HDL prefix and preparation sequence by
delegating to the extracted live owners.

=cut

sub generate_systemverilog_prelude ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};

    my $hdl = $ctx->{backend_sv_scaffold}->generate_header($fsm_module);
    $hdl .= $ctx->{backend_sv_scaffold}->generate_module_declaration($fsm_module);
    $hdl .= $ctx->{backend_sv_scaffold}->generate_state_encoding($fsm_module);
    $hdl .= $ctx->{backend_sv_scaffold}->generate_state_register($fsm_module);
    $hdl .= $ctx->{backend_sv_internal_decl}->generate_internal_signal_declarations($fsm_module);
    fsm_debug("Step 2 - Basic HDL structure generated", 3);

    $hdl .= $ctx->{enable_graph_enable_support}->generate_enable_conditions($fsm_module);
    fsm_debug("Step 3 - Enable conditions generated", 3);
    $ctx->{backend_sv_generation_prescan_preparation_support}
        ->prepare_enable_prescan();

    return $hdl;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one SystemVerilog generation-prelude owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 generate_systemverilog_prelude

Rebuilds the direct SystemVerilog HDL prefix and preparation sequence by
delegating to the extracted live owners.

=cut
