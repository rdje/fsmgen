package FSM::Composition::Top;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Composition::TopSymbols;
use FSM::Composition::ParameterBindingSupport;
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
sub parameter_default_bindings ($self) { return _clone($self->{parameter_default_bindings}) }
sub parameter_symbol_contract ($self) { return _clone($self->{parameter_symbol_contract}) }
sub top_symbols ($self) { return $self->{top_symbols} }
sub raw_ast ($self) { return _clone($self->{raw_ast}) }

sub parameter_environment ($self) {
    return undef unless @{$self->{parameter_declarations}};
    my $graph = $self->{parameter_default_graph};
    my $bindings = $self->{parameter_default_bindings};
    confess "Composition top '$self->{name}' requires resolved defaults and bindings before parameter environment capture\n"
        unless ref($graph) eq 'HASH' && ref($bindings) eq 'HASH';
    return _clone({
        scope => {kind => 'composition_top', owner => $self->{name}},
        declaration_order => $graph->{order},
        parameters => $graph->{parameters},
        default_sources => $graph->{default_sources},
        default_bindings => $bindings,
    });
}

sub symbol_contract ($self) {
    my $symbols = $self->top_symbols;
    my $contract = $symbols && $symbols->can('as_hashref') ? $symbols->as_hashref : {};
    my $imports = $self->package_imports;
    $contract->{package_import_count} = scalar(@$imports);
    $contract->{package_imports} = $imports;
    return undef unless ($contract->{constant_count} // 0) > 0
        || ($contract->{enum_count} // 0) > 0
        || ($contract->{type_count} // 0) > 0
        || @$imports;
    return $contract;
}

sub resolve_parameter_defaults ($self) {
    # A refused retry must not expose a stale or partially resolved graph.
    delete $self->{parameter_default_graph};
    delete $self->{parameter_default_bindings};
    delete $self->{parameter_symbol_contract};
    return undef unless @{$self->{parameter_declarations}};
    my $graph = FSM::ParameterDeclarationSupport->resolve_declarations(
        entries => $self->{parameter_declarations}, source_module => $self->{name},
        capture_expression => 1,
        context_prefix => "Composition top '$self->{name}' parameter",
        docs_hint => ' See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.',
        resolve_static_symbol_payload => sub ($name) {
            return $self->{top_symbols}->resolve_payload($name);
        },
    );
    my $expressions = delete $graph->{expressions};
    my %bindings;
    for my $name (@{$graph->{order}}) {
        $bindings{$name} = FSM::Composition::ParameterBindingSupport->bind_expression(
            expression => $expressions->{$name}, references => $graph->{default_sources}{$name}{references},
            parameters => $graph->{parameters}, static_symbols => $self->{top_symbols},
            scope => {kind => 'composition_top', owner => $self->{name}},
        );
    }
    my $symbol_contract = $self->symbol_contract;
    $self->{parameter_default_graph} = $graph;
    $self->{parameter_default_bindings} = \%bindings;
    $self->{parameter_symbol_contract} = _clone($symbol_contract);
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
are never inserted into static symbol lookup. Child overrides consult the real
top parameter graph separately.

C<parameter_default_graph> returns a detached graph of declaration order,
canonical parameters and authored default sources. It is undefined before
resolution, after refusal, or when no parameters are declared. A successful
retry replaces the whole graph; failure publishes no stale or partial result.
Constructor inputs and returned declaration/value/source trees are detached.

C<parameter_default_bindings> separately returns detached scoped default trees.
Real observed parameter roots remain configurable references; static symbols
keep immutable selected canonical payloads and lookup identity. Equal values
do not merge declarations, and aliases retain their immediate reference.
The original C<parameter_default_graph> shape and normalized values stay intact.
Graphs and their captured static contract publish only after complete success
and clear before a retry.

C<parameter_environment> combines those resolved products into one detached
snapshot with C<scope>, C<declaration_order>, C<parameters>, C<default_sources>
and C<default_bindings>. No-parameter tops return undef. Declared parameters
require complete successful resolution; an unresolved or failed retry refuses
capture instead of publishing an absent or stale environment. Static symbols
remain in their existing separate namespace.

C<symbol_contract> is the live canonical static-symbol/import projection.
Successful default resolution captures that projection separately as
C<parameter_symbol_contract>. Its detached getter retains the same resolution
boundary as the defaults, even if the caller later changes static caches or
retries. Mutable parameters never enter the static namespace.


Authored top C<+params> now collects these declarations; defaults resolve only
after imports. Composition planning admits the bounded scalar fixed-interface
external RTL profile through L<FSM::Composition::PlanBuilder>; generated children,
aggregate defaults and mutable top widths retain explicit refusals. Backend
types and namespaces remain target-specific. Existing static compositions retain
their behavior.

=cut
