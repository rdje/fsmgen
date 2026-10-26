package FSM::Backend::VerilogFamily::ParameterBindingEmitter;

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
    my $environment = $args{environment};
    my $scope = ref($environment) eq 'HASH' ? $environment->{scope} : undef;
    my $scope_kind = ref($scope) eq 'HASH' ? $scope->{kind} : undef;
    my $normalization_context = defined($scope_kind) && !ref($scope_kind)
        && $scope_kind eq 'composition_top' ? 'Composition binding' : 'Parameter binding';
    my $diagnostic = "$normalization_context renderer";
    my $language = $args{target_language} // 'systemverilog';
    confess "$diagnostic requires a Verilog-family target\n"
        unless !ref($language) && $language =~ /\A(?:systemverilog|sv|verilog|v)\z/;
    confess "$diagnostic requires a resolved environment\n"
        unless ref($environment) eq 'HASH'
            && ref($environment->{parameters}) eq 'HASH'
            && ref($environment->{declaration_order}) eq 'ARRAY';
    confess "$diagnostic requires an explicit direct-module or composition-top scope\n"
        unless ref($scope) eq 'HASH' && defined($scope_kind) && !ref($scope_kind)
            && $scope_kind =~ /\A(?:direct_module|composition_top)\z/
            && defined($scope->{owner}) && !ref($scope->{owner}) && length($scope->{owner});
    my %declared;
    for my $name (@{$environment->{declaration_order}}) {
        confess "$diagnostic has invalid declaration order\n"
            unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name)
                && exists($environment->{parameters}{$name}) && !$declared{$name}++;
    }
    confess "$diagnostic has incomplete declaration order\n"
        unless keys(%declared) == keys(%{$environment->{parameters}});
    my $context = {environment => $environment, references => [], active => {},
        diagnostic => $diagnostic, normalization_context => $normalization_context};
    my $text = _render($context, $args{binding});
    return {text => $text, parameter_references => $context->{references}};
}

sub _assert_scope ($context, $scope) {
    my $expected = $context->{environment}{scope};
    confess "$context->{diagnostic} encountered a foreign or missing scope\n"
        unless ref($scope) eq 'HASH'
            && defined($scope->{kind}) && !ref($scope->{kind})
            && defined($scope->{owner}) && !ref($scope->{owner})
            && $scope->{kind} eq $expected->{kind} && $scope->{owner} eq $expected->{owner};
}

sub _scalar_literal ($context, $payload) {
    confess "$context->{diagnostic} requires a scalar literal payload; raw expressions and aggregates are pending\n"
        unless ref($payload) eq 'HASH' && ($payload->{kind} // '') eq 'scalar';
    return FSM::ParameterValueSupport->canonical_value_text(
        value_ast => $payload, context => "$context->{normalization_context} scalar literal");
}

sub _render ($context, $node) {
    confess "$context->{diagnostic} requires a canonical binding node\n"
        unless ref($node) eq 'HASH';
    my $identity = refaddr($node);
    confess "$context->{diagnostic} encountered a cyclic binding tree\n"
        if $context->{active}{$identity};
    local $context->{active}{$identity} = 1;
    my $kind = $node->{kind} // '';
    if ($kind eq 'literal') {
        confess "$context->{diagnostic} requires a scalar literal source token\n"
            unless defined($node->{token}) && !ref($node->{token}) && length($node->{token});
        return FSM::ParameterValueSupport->canonical_value_text(
            value_ast => $node->{token}, context => "$context->{normalization_context} literal");
    }
    if ($kind eq 'parameter') {
        _assert_scope($context, $node->{scope});
        my $name = $node->{parameter};
        confess "$context->{diagnostic} requires an actual declared parameter\n"
            unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name)
                && exists($context->{environment}{parameters}{$name});
        confess "$context->{diagnostic} does not support an aggregate selection\n"
            unless defined($node->{suffix}) && !ref($node->{suffix}) && $node->{suffix} eq '';
        confess "$context->{diagnostic} has an inconsistent parameter token\n"
            unless defined($node->{token}) && !ref($node->{token}) && $node->{token} eq $name;
        my $parameter = $context->{environment}{parameters}{$name};
        my $payload = ref($parameter) eq 'HASH' ? $parameter->{value_payload} : undef;
        confess "$context->{diagnostic} requires a scalar parameter '$name'\n"
            unless ref($payload) eq 'HASH' && ($payload->{kind} // '') =~ /\A(?:scalar|scalar_expr)\z/;
        my $reserved = FSM::Support::HDLInstanceIdentifierPolicy->reserved_target_languages($name);
        confess "$context->{diagnostic} parameter '$name' is reserved in SystemVerilog\n"
            if grep { $_ eq 'SystemVerilog' } @$reserved;
        push @{$context->{references}}, $name;
        return $name;
    }
    if ($kind eq 'static_symbol') {
        _assert_scope($context, $node->{scope});
        confess "$context->{diagnostic} requires a static source token\n"
            unless defined($node->{token}) && !ref($node->{token}) && length($node->{token});
        return _scalar_literal($context, $node->{value_payload});
    }
    if ($kind eq 'payload') {
        return _scalar_literal($context, $node->{value});
    }
    if ($kind eq 'operator') {
        my $operator = FSM::ParameterValueSupport->normalize_expression_operator($node->{operator});
        my $source = FSM::ParameterValueSupport->normalize_expression_operator($node->{source_operator});
        confess "$context->{diagnostic} requires a canonical operator and matching source alias\n"
            unless defined($operator) && defined($source)
                && $operator eq $node->{operator} && $source eq $operator;
        my $operands = $node->{operands};
        confess "$context->{diagnostic} has invalid operator operands\n"
            unless ref($operands) eq 'ARRAY' && ($operator eq '~' ? @$operands == 1 : @$operands >= 2);
        my @rendered = map { _render($context, $_) } @$operands;
        return '(~'.$rendered[0].')' if $operator eq '~';
        return '('.join(" $operator ", @rendered).')';
    }
    confess "$context->{diagnostic} has unsupported canonical kind '$kind'\n";
}

1;

=head1 NAME

FSM::Backend::VerilogFamily::ParameterBindingEmitter - Shared canonical scalar binding rendering

=head1 DESCRIPTION

C<lower_expression> consumes a canonical C<binding>, a resolved C<environment>
and Verilog-family C<target_language>. The environment requires complete unique
C<declaration_order>, declared C<parameters> and explicit C<direct_module> or
C<composition_top> scope with an owner. It returns fresh C<text> and ordered
C<parameter_references>, preserving repeated occurrences. C<text> is a scalar
for target interpolation and retains the canonical normalizer's existing scalar
kind; this private preparation result is not a new serialized string schema.

Actual scalar parameter roots render by name after exact token/scope/type and
target-identifier checks. Canonical literals and captured static scalar payloads
share existing value normalization; validation-cache numbers never replace
mutable roots. Parentheses preserve canonical operator nesting and operand
order. Static and parameter scopes remain distinct from matching values.

The composition wrapper retains its narrower scope and existing diagnostics.
Aggregate roots/paths/structures, raw scalar-expression payloads, malformed
canonical operators, foreign scopes, incomplete declarations and recursive
trees refuse. Caller records remain read-only; results own dependency arrays.

This helper prepares scalar text. It does not itself integrate direct headers,
choose declaration order, admit source profiles or implement generic ranges.
Those consumers and complete external/runtime qualification remain separate.

=cut
