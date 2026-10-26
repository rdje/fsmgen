package FSM::Composition::ParameterBindingSupport;

use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use FSM::ParameterValueSupport;

sub bind_expression {
    my ($class, %args) = @_;
    my $scope = $args{scope};
    confess "Parameter binding requires an explicit composition-top scope\n"
        unless ref($scope) eq 'HASH' && ($scope->{kind} // '') eq 'composition_top'
            && defined($scope->{owner}) && !ref($scope->{owner}) && length($scope->{owner});
    my $parameters = $args{parameters};
    my $references = $args{references} // [];
    my $symbols = $args{static_symbols};
    confess "Parameter binding requires declared parameters and reference observations\n"
        unless ref($parameters) eq 'HASH' && ref($references) eq 'ARRAY';
    confess "Parameter binding requires a static symbol cache\n"
        unless blessed($symbols) && $symbols->can('resolve_payload');
    my $context = {scope => $scope, parameters => $parameters, references => {}, used => [], symbols => $symbols, statics => {}};
    for my $reference (@$references) {
        confess "Parameter binding has malformed reference observations\n"
            unless ref($reference) eq 'HASH'
                && !grep { !defined($reference->{$_}) || ref($reference->{$_}) } qw(parameter token suffix);
        my ($name, $token, $suffix) = @{$reference}{qw(parameter token suffix)};
        confess "Parameter binding requires actual declared parameter '$name'\n"
            unless exists($parameters->{$name}) && ref($parameters->{$name}) eq 'HASH';
        confess "Parameter binding has inconsistent reference observations for '$token'\n"
            unless $token eq $name.$suffix;
        my $prior = $context->{references}{$token};
        confess "Parameter binding has conflicting reference observations for '$token'\n"
            if $prior && ($prior->{parameter} ne $name || $prior->{suffix} ne $suffix);
        $context->{references}{$token} = $reference;
    }
    my $bound = _bind($context, $args{expression});
    my $used = $context->{used};
    confess "Parameter binding does not preserve actual reference observations\n" unless @$used == @$references;
    for my $index (0 .. $#$references) {
        for my $field (qw(parameter token suffix)) {
            confess "Parameter binding changes ordered reference observations\n"
                unless $used->[$index]{$field} eq $references->[$index]{$field};
        }
    }
    return $bound;
}

sub _bind {
    my ($context, $expression) = @_;
    confess "Parameter binding requires a canonical expression node\n" unless ref($expression) eq 'HASH';
    my $kind = $expression->{kind} // '';
    if ($kind eq 'literal' || $kind eq 'symbol') {
        my $token = $expression->{token};
        confess "Parameter binding requires a canonical source token\n" unless defined($token) && !ref($token) && length($token);
        return {kind => 'literal', token => $token} if $kind eq 'literal';
        if (my $reference = $context->{references}{$token}) {
            push @{$context->{used}}, $reference;
            return {kind => 'parameter', scope => _copy($context->{scope}),
                map {$_ => $reference->{$_}} qw(parameter token suffix)};
        }
        if (!exists $context->{statics}{$token}) {
            my $selected = $context->{symbols}->resolve_payload($token);
            confess "Parameter binding lacks a static cache for unbound canonical symbol '$token'\n" unless defined $selected;
            # Cache inputs also admit scalar literals. Reuse the canonical
            # normalizer without a resolver: static values cannot bind params.
            $context->{statics}{$token} = FSM::ParameterValueSupport->canonical_value(
                value_ast => $selected, context => "Composition static symbol '$token'",
            )->{value_payload};
        }
        return {kind => 'static_symbol', scope => _copy($context->{scope}), token => $token,
            value_payload => _copy($context->{statics}{$token})};
    }
    if ($kind eq 'payload') {
        confess "Parameter binding requires a canonical semantic payload\n"
            unless ref($expression->{value}) eq 'HASH' && defined($expression->{value}{kind});
        return {kind => 'payload', value => _copy($expression->{value})};
    }
    if ($kind eq 'operator') {
        my $operator = FSM::ParameterValueSupport->normalize_expression_operator($expression->{operator});
        my $source = FSM::ParameterValueSupport->normalize_expression_operator($expression->{source_operator});
        my $operands = $expression->{operands};
        confess "Parameter binding requires a canonical operator and authored alias\n"
            unless defined($operator) && defined($source) && $operator eq $expression->{operator} && $source eq $operator;
        confess "Parameter binding requires canonical operator operands\n"
            unless ref($operands) eq 'ARRAY' && ($operator eq '~' ? @$operands == 1 : @$operands >= 2);
        return {kind => 'operator', operator => $operator, source_operator => $expression->{source_operator},
            operands => [map {_bind($context, $_)} @$operands]};
    }
    if ($kind eq 'list') {
        my $items = $expression->{items};
        confess "Parameter binding requires canonical list items\n" unless ref($items) eq 'ARRAY' && @$items;
        return {kind => 'list', items => [map {_bind($context, $_)} @$items]};
    }
    if ($kind eq 'map') {
        my ($order, $members) = @{$expression}{qw(member_order members)};
        confess "Parameter binding requires canonical map members\n"
            unless ref($order) eq 'ARRAY' && @$order && ref($members) eq 'HASH';
        my (%bound, %seen);
        for my $name (@$order) {
            confess "Parameter binding requires unique ordered map members\n"
                unless defined($name) && !ref($name) && exists($members->{$name}) && !$seen{$name}++;
            $bound{$name} = _bind($context, $members->{$name});
        }
        confess "Parameter binding has unordered map members\n" unless keys(%bound) == keys(%$members);
        return {kind => 'map', member_order => [@$order], members => \%bound};
    }
    confess "Parameter binding has unsupported canonical expression kind '$kind'\n";
}

sub _copy {
    my ($value) = @_;
    return $value unless ref $value;
    return [map {_copy($_)} @$value] if ref($value) eq 'ARRAY';
    return {map {$_ => _copy($value->{$_})} keys %$value} if ref($value) eq 'HASH';
    confess "Parameter binding contains an unsupported reference\n";
}

1;

=head1 NAME

FSM::Composition::ParameterBindingSupport - Scoped composition parameter expression bindings

=head1 DESCRIPTION

C<bind_expression> consumes a canonical observed C<expression>, ordered actual
C<references>, resolved declared C<parameters>, an explicit composition-top
C<scope>, and the selected C<static_symbols> cache. It does not parse source,
expand aliases, infer declarations from values, or evaluate another expression.

Observed direct parameter references become C<parameter> nodes retaining
scope, parameter root, full token and aggregate suffix. The complete ordered
reference observations must agree with the bound tree; missing declarations,
unobserved symbols and discarded references refuse. Static symbols keep their
lookup scope/token and a detached canonical C<value_payload>. Selected static
cache inputs, including scalar literals, normalize through the same value
helper without a resolver and memoize per binding call. They never acquire a
configurable parameter identity from a matching value.

Literal/operator/list/map/payload nodes preserve canonical structure and source
tokens. Operator/alias validation shares the existing canonical operator table.
Map member names are structure, not symbol references. Named functions carry
ordinary per-call context, with no recursive callback ownership. Results own
all nested scope, structure and payload records.

This is private default-binding groundwork. Instance binding, validated public
IR/schema propagation, widths and HDL emission remain later stages; existing
parameter-bearing composition plans still refuse.

=cut
