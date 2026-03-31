package FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationTailSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationTailSupport - Own live post-stage direct SystemVerilog generation tail

=head1 DESCRIPTION

Owns the bounded live generation-tail family for the older direct
generated-module SystemVerilog backend path. This package centralizes:

=over 4

=item *

full post-stage HDL closeout after consolidated intermediate generation

=item *

the live composition of unified WEN/EN emission, signal-assignment emission,
and module closeout

=back

The paired C<FSM::HDL::FlattenedDT::Orchestrator> now keeps the broader
post-flattening module assembly sequence directly, but this package owns the
tail that follows the consolidated intermediate stage.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Debug;

=head2 new

Construct one SystemVerilog generation-tail owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[GenerationTailSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 generate_systemverilog_tail

Generate the direct SystemVerilog HDL tail that follows consolidated
intermediate generation.

=cut

sub generate_systemverilog_tail ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};

    my $hdl = "";

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

Constructs one SystemVerilog generation-tail owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 generate_systemverilog_tail

Generates the direct SystemVerilog HDL tail that follows consolidated
intermediate generation.

=cut
