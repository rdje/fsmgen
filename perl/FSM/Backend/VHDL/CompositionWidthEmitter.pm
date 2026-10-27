package FSM::Backend::VHDL::CompositionWidthEmitter;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Backend::VHDL::WidthExpressionEmitter;

sub lower_range ($class, %args) {
    my $port = $args{port};
    return FSM::Backend::VHDL::WidthExpressionEmitter->lower_range(%args,
        context => "VHDL composition port '" . ($port->{name} // '?') . "' width",
        required_scope_kind => 'composition_top', scope_description => 'top');
}

1;

=head1 NAME

FSM::Backend::VHDL::CompositionWidthEmitter - Prepared scalar VHDL composition port ranges

=head1 DESCRIPTION

Delegates captured C<width_contract> trees to
L<FSM::Backend::VHDL::WidthExpressionEmitter>, retaining explicit composition-top
scope and port diagnostics after natural top generic/namespace validation. Scope and ordered parameter/static
lookups must match. Parameters retain selected names; static subexpressions
fold through the shared integer evaluator. Arithmetic C<+>, C<->, C<*>, C</>
and C<%> uses explicit left-associated parentheses; C<%> renders as C<mod>.
Each default fold fits the portable natural integer range through 2147483647;
final width must be positive. Numeric port width caches never provide range
text. Even a one-bit default retains its vector range.

=head1 METHODS

=head2 lower_range

Accepts C<port> and captured C<environment>. Returns a parenthesized descending
VHDL vector range. Declared-type conflicts, foreign scopes, incomplete or wrong
lookups, cycles, aggregates, unsupported operators and invalid default arithmetic
refuse. Inputs remain read-only. Source admission, internal nets, external
override legality and compiler/runtime qualification remain separately owned.
Caller-made hashes do not acquire provenance from this helper.

=cut
