package FSM::Composition::Top;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Composition::TopSymbols;
use FSM::ParameterDeclarationSupport;

sub new ($class, %args) {
    return bless {
        name => $args{name},
        instances => _clone($args{instances} || []),
        ports_blocks => _clone($args{ports_blocks} || []),
        wiring_blocks => _clone($args{wiring_blocks} || []),
        package_imports => _clone($args{package_imports} || []),
        parameter_declarations => _clone($args{parameter_declarations} || []),
        top_symbols => $args{top_symbols} || FSM::Composition::TopSymbols->new(),
        raw_ast => _clone($args{raw_ast}),
    }, $class;
}

sub name ($self) { return $self->{name} }
sub instances ($self) { return _clone($self->{instances}) }
sub ports_blocks ($self) { return _clone($self->{ports_blocks}) }
sub wiring_blocks ($self) { return _clone($self->{wiring_blocks}) }
sub package_imports ($self) { return _clone($self->{package_imports}) }
sub parameter_declarations ($self) { return _clone($self->{parameter_declarations}) }
sub parameter_default_graph ($self) { return _clone($self->{parameter_default_graph}) }
sub top_symbols ($self) { return $self->{top_symbols} }
sub raw_ast ($self) { return _clone($self->{raw_ast}) }

sub resolve_parameter_defaults ($self) {
    # A refused retry must not expose a stale or partially resolved graph.
    delete $self->{parameter_default_graph};
    return undef unless @{$self->{parameter_declarations}};
    my $graph = FSM::ParameterDeclarationSupport->resolve_declarations(
        entries => $self->{parameter_declarations}, source_module => $self->{name},
        context_prefix => "Composition top '$self->{name}' parameter",
        docs_hint => ' See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.',
        resolve_static_symbol_payload => sub ($name) {
            return $self->{top_symbols}->resolve_payload($name);
        },
    );
    $self->{parameter_default_graph} = $graph;
    return $self->parameter_default_graph;
}

sub _clone ($value) {
    return undef unless defined $value;

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => _clone($value->{$_}) } sort keys %$value
        };
    }

    if (ref($value) eq 'ARRAY') {
        return [ map { _clone($_) } @$value ];
    }

    return $value;
}

1;

=head1 NAME

FSM::Composition::Top - Typed composition declarations and detached parameter defaults

=head1 DESCRIPTION

C<parameter_declarations> owns parsed name/value_ast records separately from
static C<top_symbols>. C<resolve_parameter_defaults> is called after package
imports and uses L<FSM::ParameterDeclarationSupport>. Declared parameter roots
select their actual declaration before static fallback inside defaults; they
are never inserted into static symbol lookup or child override evaluation.

C<parameter_default_graph> returns a detached graph of declaration order,
canonical parameters and authored default sources. It is undefined before
resolution, after refusal, or when no parameters are declared. A successful
retry replaces the whole graph; failure publishes no stale or partial result.
Constructor inputs and returned declaration/value/source trees are detached.

This internal container support adds no source admission. Composition planning
currently refuses parameter-bearing tops until symbolic lowering can preserve
their configuration. Existing static compositions retain their behavior.

=cut
