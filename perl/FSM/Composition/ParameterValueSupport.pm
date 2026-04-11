package FSM::Composition::ParameterValueSupport;

=head1 NAME

FSM::Composition::ParameterValueSupport - Parameter/generic value helpers

=head1 DESCRIPTION

Compatibility shim for the neutral C<FSM::ParameterValueSupport> owner. New code
should depend on the neutral package directly.

=cut

use v5.20;
use strict;
use warnings;
use parent 'FSM::ParameterValueSupport';

1;

__END__

=head1 METHODS

=head2 canonical_value_text

Returns backend-ready literal text for the bounded parameter/generic scalar and
aggregate value surface.

=cut
