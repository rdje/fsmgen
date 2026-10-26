package FSM::ParameterBindingSupport;

use strict;
use warnings;
use Carp qw(confess);
use FSM::ParameterValueSupport;

sub bind_expression {
    my ($class, %args) = @_;
    my $scope = $args{scope};
    confess "Parameter binding requires an explicit direct-module or composition-top scope\n"
        unless ref($scope) eq 'HASH' && !ref($scope->{kind})
            && ($scope->{kind} // '') =~ /\A(?:direct_module|composition_top)\z/
            && defined($scope->{owner}) && !ref($scope->{owner}) && length($scope->{owner});
    my $parameters = $args{parameters};
    my $references = $args{references} // [];
    my $resolve_static = $args{resolve_static_symbol_payload};
    confess "Parameter binding requires declared parameters and reference observations\n"
        unless ref($parameters) eq 'HASH' && ref($references) eq 'ARRAY';
    confess "Parameter binding requires a static payload resolver\n"
        unless ref($resolve_static) eq 'CODE';
    my $static_context = $args{static_context_prefix} // 'Parameter static symbol';
    confess "Parameter binding requires a static diagnostic label\n"
        unless !ref($static_context) && length($static_context);
    my $context = {
        scope => $scope, parameters => $parameters, references => {}, used => [],
        resolve_static => $resolve_static, static_context => $static_context, statics => {},
    };
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
            my $selected = $context->{resolve_static}->($token);
            confess "Parameter binding lacks a static cache for unbound canonical symbol '$token'\n" unless defined $selected;
            # Cache inputs also admit scalar literals. Reuse the canonical
            # normalizer without a resolver: static values cannot bind params.
            $context->{statics}{$token} = FSM::ParameterValueSupport->canonical_value(
                value_ast => $selected, context => "$context->{static_context} '$token'",
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

FSM::ParameterBindingSupport - Canonical observed parameter expression bindings

=head1 DESCRIPTION

C<bind_expression> consumes the existing evaluator's finite canonical
C<expression>, ordered actual C<references>, resolved declared C<parameters>,
and an explicit C<scope> with C<kind> C<direct_module> or C<composition_top>
and a nonempty C<owner>. C<resolve_static_symbol_payload> is a transient callback
for symbols not observed as declared parameter references. The optional
C<static_context_prefix> preserves the caller's static-normalization diagnostic
label. This helper does not parse source or evaluate another expression.

Observed parameter roots retain their scope, immediate identity, full token
and aggregate suffix. The complete ordered observations must match the tree;
missing declarations, inconsistent/discarded references, unavailable static
symbols and unknown canonical structures refuse. Equal default values never
supply binding identity. Literal/operator/list/map/payload structure and
operator aliases retain their canonical meaning. Map field names are structure.

Static selections normalize through L<FSM::ParameterValueSupport> without a
resolver, memoize within the call and become detached semantic payloads beside
their static token and scope. Results own every nested scope/structure/payload;
no callback, symbol cache or recursive closure is retained. The composition
wrapper keeps its narrower scope and static-object contract.

This shared traversal adds no direct Core capture, public schema, source
admission, generic range or HDL consumer. Those boundaries require their own
producer and target checks.

=cut
