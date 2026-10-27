package FSM::Backend::VerilogFamily::CompositionWidthEmitter;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Backend::VerilogFamily::WidthExpressionEmitter;

sub lower_range ($class, %args) {
    my $port = $args{port};
    return FSM::Backend::VerilogFamily::WidthExpressionEmitter->lower_range(%args,
        context => "Composition port '" . ($port->{name} // '?') . "' width",
        required_scope_kind => 'composition_top', scope_description => 'top');
}

1;

=head1 NAME

FSM::Backend::VerilogFamily::CompositionWidthEmitter - Prepared scalar composition port ranges

=head1 DESCRIPTION

Delegates captured C<width_contract> trees to
L<FSM::Backend::VerilogFamily::WidthExpressionEmitter>, retaining the explicit
composition-top scope and composition-port diagnostics for the structural
emitter. Scope and ordered parameter/static lookup records must
match the actual expression. Selected parameters retain their declared names;
static integer subexpressions resolve through captured payloads. The shared
width evaluator checks nonnegative intermediates and positive final defaults.
Numeric port width caches never supply range text. A parameter-dependent range
is retained even when its default is one bit.

=head1 METHODS

=head2 lower_range

Accepts C<port>, captured C<environment> and C<target_language>, after canonical
top declaration validation. Returns a packed range and trailing space. Static
expression subtrees fold to decimal integers; symbolic operations use explicit
left-associated parentheses. Declared types combined with width contracts,
foreign scopes, missing/extra/wrong lookups, unsupported shapes, aggregates and
invalid default arithmetic refuse. Caller records remain read-only.
Source admission, override legality, nets, VHDL generics and external HDL
qualification remain separately owned; this helper does not attest caller-made
hash provenance or enable those profiles.

=cut
