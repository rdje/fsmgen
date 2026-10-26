package FSM::Backend::VerilogFamily::CompositionBindingEmitter;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(refaddr);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::ParameterValueSupport;
use FSM::Support::HDLInstanceIdentifierPolicy;

sub lower_expression ($class, %args) {
    my $language = $args{target_language} // 'systemverilog';
    confess "Composition binding renderer requires a Verilog-family target\n"
        unless !ref($language) && $language =~ /\A(?:systemverilog|sv|verilog|v)\z/;
    my $environment = $args{environment};
    confess "Composition binding renderer requires a resolved environment\n"
        unless ref($environment) eq 'HASH'
            && ref($environment->{parameters}) eq 'HASH'
            && ref($environment->{declaration_order}) eq 'ARRAY';
    my $scope = $environment->{scope};
    confess "Composition binding renderer requires an explicit composition-top scope\n"
        unless ref($scope) eq 'HASH' && ($scope->{kind} // '') eq 'composition_top'
            && defined($scope->{owner}) && !ref($scope->{owner}) && length($scope->{owner});
    my %declared;
    for my $name (@{$environment->{declaration_order}}) {
        confess "Composition binding renderer has invalid declaration order\n"
            unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name)
                && exists($environment->{parameters}{$name}) && !$declared{$name}++;
    }
    confess "Composition binding renderer has incomplete declaration order\n"
        unless keys(%declared) == keys(%{$environment->{parameters}});
    my $context = {environment => $environment, references => [], active => {}};
    my $text = _render($context, $args{binding});
    return {text => $text, parameter_references => $context->{references}};
}

sub _assert_scope ($context, $scope) {
    my $expected = $context->{environment}{scope};
    confess "Composition binding renderer encountered a foreign or missing scope\n"
        unless ref($scope) eq 'HASH'
            && defined($scope->{kind}) && !ref($scope->{kind})
            && defined($scope->{owner}) && !ref($scope->{owner})
            && $scope->{kind} eq $expected->{kind} && $scope->{owner} eq $expected->{owner};
}

sub _scalar_literal ($payload) {
    confess "Composition binding renderer requires a scalar literal payload; raw expressions and aggregates are pending\n"
        unless ref($payload) eq 'HASH' && ($payload->{kind} // '') eq 'scalar';
    return FSM::ParameterValueSupport->canonical_value_text(
        value_ast => $payload, context => 'Composition binding scalar literal');
}

sub _render ($context, $node) {
    confess "Composition binding renderer requires a canonical binding node\n"
        unless ref($node) eq 'HASH';
    my $identity = refaddr($node);
    confess "Composition binding renderer encountered a cyclic binding tree\n"
        if $context->{active}{$identity};
    local $context->{active}{$identity} = 1;
    my $kind = $node->{kind} // '';
    if ($kind eq 'literal') {
        confess "Composition binding renderer requires a scalar literal source token\n"
            unless defined($node->{token}) && !ref($node->{token}) && length($node->{token});
        return FSM::ParameterValueSupport->canonical_value_text(
            value_ast => $node->{token}, context => 'Composition binding literal');
    }
    if ($kind eq 'parameter') {
        _assert_scope($context, $node->{scope});
        my $name = $node->{parameter};
        confess "Composition binding renderer requires an actual declared parameter\n"
            unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name)
                && exists($context->{environment}{parameters}{$name});
        confess "Composition binding renderer does not support an aggregate selection\n"
            unless defined($node->{suffix}) && !ref($node->{suffix}) && $node->{suffix} eq '';
        confess "Composition binding renderer has an inconsistent parameter token\n"
            unless defined($node->{token}) && !ref($node->{token}) && $node->{token} eq $name;
        my $parameter = $context->{environment}{parameters}{$name};
        my $payload = ref($parameter) eq 'HASH' ? $parameter->{value_payload} : undef;
        confess "Composition binding renderer requires a scalar parameter '$name'\n"
            unless ref($payload) eq 'HASH' && ($payload->{kind} // '') =~ /\A(?:scalar|scalar_expr)\z/;
        my $reserved = FSM::Support::HDLInstanceIdentifierPolicy->reserved_target_languages($name);
        confess "Composition binding renderer parameter '$name' is reserved in SystemVerilog\n"
            if grep { $_ eq 'SystemVerilog' } @$reserved;
        push @{$context->{references}}, $name;
        return $name;
    }
    if ($kind eq 'static_symbol') {
        _assert_scope($context, $node->{scope});
        confess "Composition binding renderer requires a static source token\n"
            unless defined($node->{token}) && !ref($node->{token}) && length($node->{token});
        return _scalar_literal($node->{value_payload});
    }
    if ($kind eq 'payload') {
        return _scalar_literal($node->{value});
    }
    if ($kind eq 'operator') {
        my $operator = FSM::ParameterValueSupport->normalize_expression_operator($node->{operator});
        my $source = FSM::ParameterValueSupport->normalize_expression_operator($node->{source_operator});
        confess "Composition binding renderer requires a canonical operator and matching source alias\n"
            unless defined($operator) && defined($source)
                && $operator eq $node->{operator} && $source eq $operator;
        my $operands = $node->{operands};
        confess "Composition binding renderer has invalid operator operands\n"
            unless ref($operands) eq 'ARRAY' && ($operator eq '~' ? @$operands == 1 : @$operands >= 2);
        my @rendered = map { _render($context, $_) } @$operands;
        return '(~'.$rendered[0].')' if $operator eq '~';
        return '('.join(" $operator ", @rendered).')';
    }
    confess "Composition binding renderer has unsupported canonical kind '$kind'\n";
}

1;

=head1 NAME

FSM::Backend::VerilogFamily::CompositionBindingEmitter - Canonical scalar composition binding rendering

=head1 DESCRIPTION

Internal groundwork for structural HDL emission. This helper does not enable
parameter-bearing source plans or change either structural emitter's pending
parameter/width guard. VHDL rendering and aggregate bindings remain pending.

=head1 METHODS

=head2 lower_expression

Consumes a canonical C<binding>, its resolved C<environment>, and a Verilog-family
C<target_language>. Returns C<text> and an ordered C<parameter_references> list,
including repeated occurrences. The environment must have complete unique
C<declaration_order> membership and an explicit composition-top C<scope>.

Selected scalar parameter roots render by name after exact scope/token checks;
no parameter validation text or payload value is substituted. Static symbols
and semantic scalar payloads use canonical literal normalization without a
symbol resolver. Raw C<scalar_expr> payload text, aggregate nodes and aggregate
parameter paths refuse. Operator aliases/arity use the canonical operator
contract; explicit parentheses preserve nesting and operand order. Caller trees
are read-only and recursive caller trees refuse. Returned dependency lists are
owned by the result. Top namespace reservation, declaration ordering, full type
legality, port widths and actual emitter integration remain separately owned.

=cut
