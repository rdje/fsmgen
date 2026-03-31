package FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationStructuralPreludeSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationStructuralPreludeSupport - Own live pre-stage direct SystemVerilog structural prelude

=head1 DESCRIPTION

Owns the bounded live structural-prelude family for the older direct
generated-module SystemVerilog backend path. This package centralizes:

=over 4

=item *

the structural HDL prefix that must be emitted before enable-oriented
preparation can run

=item *

the live composition of scaffold rendering and internal declaration rendering
for one direct backend module body

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPreludeSupport>
now keeps the broader pre-stage prefix assembly, but this package owns the
purely structural prefix that comes before enable-condition generation and
prescan preparation.

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

Generate the direct SystemVerilog structural prefix that must exist before
enable-oriented pre-stage preparation can run.

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

Generates the direct SystemVerilog structural prefix that must exist before
enable-oriented pre-stage preparation can run.

=cut
