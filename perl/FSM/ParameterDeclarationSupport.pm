package FSM::ParameterDeclarationSupport;

use strict;
use warnings;
use Carp qw(confess);
use FSM::ParameterValueSupport;

sub resolve_declarations {
    my ($class, %args) = @_;
    my $entries = $args{entries} // [];
    confess "Parameter declaration resolution requires parsed entries\n" unless ref($entries) eq 'ARRAY';
    my $source_module = $args{source_module};
    confess "Parameter declaration resolution requires an explicit source module\n"
        unless defined($source_module) && !ref($source_module) && length($source_module);
    for my $name (qw(resolve_static_symbol_payload on_resolved)) {
        confess "Parameter declaration resolution requires a '$name' callback\n"
            if defined($args{$name}) && ref($args{$name}) ne 'CODE';
    }
    my $context = {
        entries => {}, order => [], resolved => {}, sources => {}, visiting => {}, stack => [],
        source_module => $source_module, boundary_hint => $args{boundary_hint} // '',
        docs_hint => $args{docs_hint} // '', context_prefix => $args{context_prefix} // 'Direct source parameter',
        resolve_static_symbol_payload => $args{resolve_static_symbol_payload}, on_resolved => $args{on_resolved},
        capture_expression => $args{capture_expression} ? 1 : 0, expressions => {},
    };
    for my $entry (@$entries) {
        confess "Parameter declaration resolution requires named value entries\n"
            unless ref($entry) eq 'HASH' && defined($entry->{name}) && !ref($entry->{name})
                && length($entry->{name}) && exists($entry->{value_ast});
        my $name = $entry->{name};
        confess "Malformed '+params' entry for parameter '$name' in source '$source_module'. "
            . "Each '+params' declaration may bind a parameter/generic name at most once so one default value remains unambiguous. "
            . $context->{boundary_hint}
            if exists $context->{entries}{$name};
        $context->{entries}{$name} = $entry;
        push @{$context->{order}}, $name;
    }
    for my $name (@{$context->{order}}) {
        my $value = _resolve_parameter($context, $name);
        # Registration stays in source order, even when lazy dependencies were
        # resolved earlier. Consumers cannot rewrite the resolver's own cache.
        $context->{on_resolved}->($name, _copy($value), _copy($context->{sources}{$name}))
            if $context->{on_resolved};
    }
    my $result = {order => _copy($context->{order}), parameters => _copy($context->{resolved}),
        default_sources => _copy($context->{sources})};
    $result->{expressions} = _copy($context->{expressions}) if $context->{capture_expression};
    return $result;
}

sub _resolve_parameter {
    my ($context, $name) = @_;
    return $context->{resolved}{$name} if exists $context->{resolved}{$name};
    if ($context->{visiting}{$name}) {
        my @cycle = (@{$context->{stack}}, $name);
        confess "Malformed '+params' dependency graph in source '$context->{source_module}'. "
            . "The active '+params' contract resolves normal non-cyclic parameter references without depending on declaration order, but parameter dependency cycles are blocked. "
            . "Cycle: " . join(' -> ', map {"parameter '$_'"} @cycle) . ". " . $context->{boundary_hint};
    }
    my $entry = $context->{entries}{$name} or return undef;
    $context->{visiting}{$name} = 1;
    push @{$context->{stack}}, $name;
    my $expression = _copy($entry->{value_ast});
    my @references;
    my $value = FSM::ParameterValueSupport->canonical_value(
        value_ast => $entry->{value_ast}, context => "$context->{context_prefix} '$name'",
        docs_hint => $context->{docs_hint},
        capture_expression => $context->{capture_expression},
        resolve_symbol_payload => sub {return _resolve_reference($context, \@references, $_[0])},
    );
    $context->{expressions}{$name} = delete $value->{value_expression} if $context->{capture_expression};
    pop @{$context->{stack}};
    delete $context->{visiting}{$name};
    $context->{sources}{$name} = {parameter => $name, source_module => $context->{source_module},
        expression => $expression, references => \@references};
    $context->{resolved}{$name} = $value;
    return $value;
}

sub _resolve_reference {
    my ($context, $references, $symbol) = @_;
    if (my $reference = __PACKAGE__->declared_reference($context->{entries}, $symbol)) {
        my $value = _resolve_parameter($context, $reference->{parameter});
        my $payload;
        if (ref($value) eq 'HASH') {
            $payload = length($reference->{suffix})
                ? FSM::ParameterValueSupport->resolve_payload_path($value->{value_payload}, $reference->{suffix})
                : $value->{value_payload};
        }
        push @$references, $reference if defined $payload;
        return $payload;
    }
    return $context->{resolve_static_symbol_payload}->($symbol) if $context->{resolve_static_symbol_payload};
    return undef;
}

sub declared_reference {
    my ($class, $declarations, $symbol) = @_;
    confess "Parameter reference selection requires declared names\n" unless ref($declarations) eq 'HASH';
    return undef unless defined($symbol) && !ref($symbol);
    return {parameter => $symbol, token => $symbol, suffix => ''} if exists $declarations->{$symbol};
    if ($symbol =~ /^([a-zA-Z_]\w*)((?:\.[a-zA-Z_]\w*|\[\d+\])+)\z/ && exists $declarations->{$1}) {
        return {parameter => $1, token => $symbol, suffix => $2};
    }
    return undef;
}

# Preserve admitted frontend trees and semantic payloads before canonical
# normalization inspects scalar flags. Other reference kinds still reach the
# existing canonical validator rather than acquiring a separate evaluation rule.
sub _copy {
    my ($value) = @_;
    return [map {_copy($_)} @$value] if ref($value) eq 'ARRAY';
    return {map {$_ => _copy($value->{$_})} keys %$value} if ref($value) eq 'HASH';
    return $value;
}

1;

=head1 NAME

FSM::ParameterDeclarationSupport - Canonical source-aware parameter declaration graphs

=head1 DESCRIPTION

C<resolve_declarations(%args)> resolves parsed C<entries> (name/value_ast pairs)
in an explicit C<source_module>. It shares the existing
L<FSM::ParameterValueSupport> value and aggregate-path evaluator. Real declared
parameter roots take precedence over C<resolve_static_symbol_payload> fallback.
Acyclic forward references work; duplicate declarations and cycles refuse.

The detached result contains declaration C<order>, normalized C<parameters> and
C<default_sources>. Sources retain the original expression and ordered direct
parameter root/token/suffix observations at successful resolution branches.
Static and literal values acquire no invented parameter reference.

Optional C<on_resolved> receives detached name/value/source records in original
declaration order, after lazy resolution. It can register each declaration
without rewriting the resolver cache or later aliases. C<boundary_hint>,
C<docs_hint> and C<context_prefix> retain the caller's diagnostic contract.

C<declared_reference($declarations, $symbol)> shares exact declared-root and
aggregate-suffix selection between lazy defaults and resolved instance values.
It returns parameter/token/suffix identity or undef for an unrelated root. A
selected root still needs a valid payload path; consumers must refuse that
path instead of falling through to a static namespace with the same spelling.

With C<capture_expression> enabled, C<expressions> separately records canonical
source trees keyed by parameter name. Expression observations never enter the
normalized parameter values or C<on_resolved> registration records. Disabled
capture keeps the existing graph shape. Lazy dependencies still register in
source order, and every returned expression is detached.

Named private functions carry ordinary per-call context. No self-referential
resolver callback survives success or failure. This helper adds no source
grammar, symbolic HDL emission or top-parameter feature by itself. Separate
static-symbol resolver ownership remains separately tracked.

=cut
