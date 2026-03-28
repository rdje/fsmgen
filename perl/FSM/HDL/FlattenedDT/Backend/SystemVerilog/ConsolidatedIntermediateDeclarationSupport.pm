package FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateDeclarationSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateDeclarationSupport - Render direct consolidated intermediate wire declarations

=head1 DESCRIPTION

Owns the bounded declaration-rendering family for the older direct
generated-module SystemVerilog consolidated intermediate path. This package
centralizes:

=over 4

=item *

width-aware declaration rendering for prepared consolidated intermediate
signals

=item *

the direct wire declaration block consumed by the narrowed consolidated
emitter

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport>
keeps width normalization and inference, the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateAssignmentSupport>
keeps prepared assign emission, and the paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateEmitter>
now narrows further to block composition over those extracted rendering owners.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

=head2 new

Construct one consolidated-intermediate declaration owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[ConsolidatedIntermediateDeclarationSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 render_consolidated_intermediate_declarations

Render the prepared consolidated intermediate wire declarations from the
prepared block contract.

=cut

sub render_consolidated_intermediate_declarations ($self, $prepared_block) {
    my $ctx = $self->{flattened_dt};
    my $width_support = $ctx->{backend_sv_intermediate_width_support};
    my $filtered_signals = $prepared_block->{filtered_signals} || {};
    my $sorted_signals = $prepared_block->{sorted_signals} || [];
    my $hdl = '';

    for my $signal_name (@{$sorted_signals}) {
        my $signal_info = $filtered_signals->{$signal_name};
        my $width = $width_support->resolve_intermediate_signal_width($signal_name, $signal_info, $filtered_signals);

        if ($width > 1) {
            $hdl .= "  wire [" . ($width - 1) . ":0] $signal_name;\n";
        } else {
            $hdl .= "  wire $signal_name;\n";
        }
    }

    return $hdl;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one consolidated-intermediate declaration owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 render_consolidated_intermediate_declarations

Renders the prepared consolidated intermediate wire declarations from the
prepared block contract.

=cut
