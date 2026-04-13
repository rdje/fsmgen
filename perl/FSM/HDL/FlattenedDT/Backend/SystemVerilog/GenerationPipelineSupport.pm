package FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPipelineSupport;

=head1 NAME

FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPipelineSupport - Compatibility shell over live post-flattening direct SystemVerilog assembly

=head1 DESCRIPTION

Keeps a directly testable compatibility shell for the older direct
generated-module SystemVerilog backend path. This package centralizes:

=over 4

=item *

full post-flattening direct SystemVerilog assembly once the decision trees
have already been flattened and the direct backend prelude has been
established

=item *

compatibility delegation to the live post-flattening assembly owner

=back

The paired
C<FSM::HDL::FlattenedDT::Backend::SystemVerilog::PostFlatteningAssemblySupport>
now owns the live post-flattening scaffold/declaration/enable/stage/tail
sequence, and this package survives only as a compatibility shell over that
live owner.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

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

    return $ctx->{backend_sv_post_flattening_assembly_support}
        ->generate_systemverilog_module($fsm_module);
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one SystemVerilog generation-pipeline owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 generate_systemverilog_module

Rebuilds the full direct SystemVerilog module body and closeout by delegating
to the live post-flattening assembly owner.

=cut
