package FSM::Synthesis::EnableGraph;

=head1 NAME

FSM::Synthesis::EnableGraph - Thin synthesis-context shell for the direct backend path

=head1 DESCRIPTION

This package is now the thin synthesis-context shell for the older direct
generated-module backend path. It keeps only the live backend context anchor
and delegates real bounded behavior to explicit support owners such as:

=over 4

=item *

C<FSM::Synthesis::EnableGraph::SignalSupport>

=item *

C<FSM::Synthesis::EnableGraph::AssignmentSupport>

=item *

C<FSM::Synthesis::EnableGraph::ASTSupport>

=item *

C<FSM::Synthesis::EnableGraph::CaptureSupport>

=item *

C<FSM::Synthesis::EnableGraph::EnableSupport>

=item *

C<FSM::Synthesis::EnableGraph::FactorizationSupport>

=item *

C<FSM::Synthesis::EnableGraph::IntermediateSignalSupport>

=item *

C<FSM::Synthesis::EnableGraph::ModulePlanningSupport>

=back

That split keeps the backend ownership boundary explicit while reducing the
remaining gravity inside the legacy direct synthesis owner itself.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

=head2 new

Construct one thin C<EnableGraph> shell bound to a live
C<FSM::HDL::FlattenedDT> context.

=cut

sub new($class, %args) {
    Carp::confess "EnableGraph requires flattened_dt" unless $args{flattened_dt};
    return bless {
        flattened_dt => $args{flattened_dt},
    }, $class;
}

1;
