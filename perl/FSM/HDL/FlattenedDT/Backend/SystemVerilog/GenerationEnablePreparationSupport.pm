package FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationEnablePreparationSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationEnablePreparationSupport - Compatibility shell for direct SystemVerilog enable preparation

=head1 DESCRIPTION

Keeps a directly testable compatibility shell for the older direct
generated-module SystemVerilog backend path. This package centralizes:

=over 4

=item *

the older non-structural pre-stage HDL preparation that follows scaffold and
internal declaration emission

=item *

compatibility composition of enable-condition generation plus the extracted
prescan-preparation owner before the consolidated intermediate stage runs

=back

The paired C<FSM::HDL::FlattenedDT::Orchestrator> now reaches
enable-condition generation and the extracted prescan-preparation owner
directly after structural-prelude assembly, so this package survives only as
a compatibility shell outside the live backend path. The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPrescanPreparationSupport>
keeps logical-operation counting plus WEN/EN prescan over the direct backend
state.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;

=head2 new

Construct one SystemVerilog enable-preparation owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[GenerationEnablePreparationSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 generate_enable_preparation

Generate the direct SystemVerilog enable-condition fragment and prepare the
backend state that must exist before consolidated intermediate generation can
run.

=cut

sub generate_enable_preparation ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};

    my $hdl = $ctx->{enable_graph_enable_support}->generate_enable_conditions($fsm_module);
    fsm_debug("Step 3 - Enable conditions generated", 3);

    $ctx->{backend_sv_generation_prescan_preparation_support}
        ->prepare_enable_prescan();

    return $hdl;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one SystemVerilog enable-preparation owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 generate_enable_preparation

Generates the direct SystemVerilog enable-condition fragment and prepares the
backend state that must exist before consolidated intermediate generation can
run.

=cut
