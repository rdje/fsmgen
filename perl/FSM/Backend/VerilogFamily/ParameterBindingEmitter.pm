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
    my $context = _render_context(%args);
    my $text = _render($context, $args{binding});
    return {text => $text, parameter_references => $context->{references}};
}

sub lower_default ($class, %args) {
    my $context = _render_context(%args);
    confess "$context->{diagnostic} default profile requires direct-module scope\n"
        unless $context->{environment}{scope}{kind} eq 'direct_module';
    my $binding = _prepare_default($context, $args{binding});
    # Preparation validates scalar leaves too. Only the final rendered tree
    # owns the output dependency list, so those visits must not count twice.
    $context->{references} = [];
    my $text = _is_aggregate_payload($binding)
        ? FSM::ParameterValueSupport->canonical_value_text(
            value_ast => $binding->{value}, context => "$context->{diagnostic} static aggregate")
        : _render($context, $binding);
    return {text => $text, parameter_references => $context->{references}};
}

sub _render_context (%args) {
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
    return {environment => $environment, references => [], active => {}, prepare_active => {},
        diagnostic => $diagnostic, normalization_context => $normalization_context};
}

sub _is_aggregate_payload ($node) {
    return ($node->{kind} // '') eq 'payload'
        && ($node->{value}{kind} // '') =~ /\A(?:list|map)\z/;
}

sub _operator_operands ($context, $node) {
    my $operator = FSM::ParameterValueSupport->normalize_expression_operator($node->{operator});
    my $source = FSM::ParameterValueSupport->normalize_expression_operator($node->{source_operator});
    confess "$context->{diagnostic} requires a canonical operator and matching source alias\n"
        unless defined($operator) && defined($source)
            && $operator eq $node->{operator} && $source eq $operator;
    my $operands = $node->{operands};
    confess "$context->{diagnostic} has invalid operator operands\n"
        unless ref($operands) eq 'ARRAY' && ($operator eq '~' ? @$operands == 1 : @$operands >= 2);
    return ($operator, $operands);
}

sub _map_order ($context, $node) {
    my ($order, $members) = @{$node}{qw(member_order members)};
    confess "$context->{diagnostic} requires complete ordered map members\n"
        unless ref($order) eq 'ARRAY' && @$order && ref($members) eq 'HASH'
            && @$order == keys(%$members);
    my %seen;
    for my $name (@$order) {
        confess "$context->{diagnostic} requires unique declared map members\n"
            unless defined($name) && !ref($name) && exists($members->{$name}) && !$seen{$name}++;
    }
    return $order;
}

sub _validate_static_payload ($context, $payload, $active = undef) {
    confess "$context->{diagnostic} requires a static literal payload\n" unless ref($payload) eq 'HASH';
    $active //= {};
    my $identity = refaddr($payload);
    confess "$context->{diagnostic} encountered a cyclic static payload\n" if $active->{$identity};
    local $active->{$identity} = 1;
    my $kind = $payload->{kind} // '';
    if ($kind eq 'scalar') {
        FSM::ParameterValueSupport->canonical_value(value_ast => $payload,
            context => "$context->{diagnostic} static literal");
    } elsif ($kind eq 'list') {
        confess "$context->{diagnostic} requires non-empty static list items\n"
            unless ref($payload->{items}) eq 'ARRAY' && @{$payload->{items}};
        _validate_static_payload($context, $_, $active) for @{$payload->{items}};
    } elsif ($kind eq 'map') {
        my $order = _map_order($context, $payload);
        _validate_static_payload($context, $payload->{members}{$_}, $active) for @$order;
    } else {
        confess "$context->{diagnostic} requires a literal payload; '$kind' is unsupported\n";
    }
}

# This reconstructs inputs for the existing evaluator, never HDL text. It is
# called only after preparation proves that the subtree has no mutable roots.
sub _immutable_value_ast ($node) {
    my $kind = $node->{kind};
    return $node->{token} if $kind eq 'literal';
    return $node->{value} if $kind eq 'payload';
    return $node->{value_payload} if $kind eq 'static_symbol';
    return [$node->{operator}, map {_immutable_value_ast($_)} @{$node->{operands}}]
        if $kind eq 'operator';
    confess "Parameter default static evaluation encountered a mutable binding\n";
}

sub _fold_static ($context, $value_ast) {
    my $value = FSM::ParameterValueSupport->canonical_value(value_ast => $value_ast,
        context => "$context->{diagnostic} immutable aggregate default");
    return {kind => 'payload', value => $value->{value_payload}};
}

sub _refuse_mutable_aggregate ($context, $start) {
    confess "$context->{diagnostic} aggregate default cannot preserve mutable parameter dependency '"
        . $context->{references}[$start] . "'; packed aggregate relationships are unsupported\n"
        if @{$context->{references}} > $start;
}

sub _prepare_default ($context, $node) {
    confess "$context->{diagnostic} requires a canonical binding node\n" unless ref($node) eq 'HASH';
    my $identity = refaddr($node);
    confess "$context->{diagnostic} encountered a cyclic binding tree\n" if $context->{prepare_active}{$identity};
    local $context->{prepare_active}{$identity} = 1;
    my $kind = $node->{kind} // '';
    if ($kind eq 'literal' || $kind eq 'parameter') {
        if ($kind eq 'parameter') {
            _assert_scope($context, $node->{scope});
            my $name = $node->{parameter};
            confess "$context->{diagnostic} requires an actual declared parameter\n"
                unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name)
                    && exists($context->{environment}{parameters}{$name});
            confess "$context->{diagnostic} has an inconsistent parameter token or selection\n"
                unless defined($node->{suffix}) && !ref($node->{suffix})
                    && defined($node->{token}) && !ref($node->{token})
                    && $node->{token} eq $name.$node->{suffix};
            my $info = $context->{environment}{parameters}{$name};
            my $payload = ref($info) eq 'HASH' ? $info->{value_payload} : undef;
            confess "$context->{diagnostic} aggregate selection cannot preserve mutable parameter '$node->{token}'\n"
                if (defined($node->{suffix}) && !ref($node->{suffix}) && length($node->{suffix}))
                    || (ref($payload) eq 'HASH' && ($payload->{kind} // '') =~ /\A(?:list|map)\z/);
        }
        _render($context, $node);
        return $node;
    }
    if ($kind eq 'static_symbol' || $kind eq 'payload') {
        if ($kind eq 'static_symbol') {
            _assert_scope($context, $node->{scope});
            confess "$context->{diagnostic} requires a static source token\n"
                unless defined($node->{token}) && !ref($node->{token}) && length($node->{token});
        }
        my $payload = $kind eq 'payload' ? $node->{value} : $node->{value_payload};
        _validate_static_payload($context, $payload);
        return _fold_static($context, $payload) if ($payload->{kind} // '') ne 'scalar';
        _render($context, $node);
        return $node;
    }
    my $start = @{$context->{references}};
    if ($kind eq 'operator') {
        my ($operator, $operands) = _operator_operands($context, $node);
        my @prepared = map {_prepare_default($context, $_)} @$operands;
        if (grep {_is_aggregate_payload($_)} @prepared) {
            _refuse_mutable_aggregate($context, $start);
            return _fold_static($context, [$operator, map {_immutable_value_ast($_)} @prepared]);
        }
        return {%$node, operands => \@prepared};
    }
    if ($kind eq 'list') {
        confess "$context->{diagnostic} requires non-empty canonical list items\n"
            unless ref($node->{items}) eq 'ARRAY' && @{$node->{items}};
        my @prepared = map {_prepare_default($context, $_)} @{$node->{items}};
        _refuse_mutable_aggregate($context, $start);
        return _fold_static($context, {kind => 'list', items => [map {_immutable_value_ast($_)} @prepared]});
    }
    if ($kind eq 'map') {
        my $order = _map_order($context, $node);
        my %prepared = map {$_ => _prepare_default($context, $node->{members}{$_})} @$order;
        _refuse_mutable_aggregate($context, $start);
        return _fold_static($context, {kind => 'map', member_order => $order,
            members => {map {$_ => _immutable_value_ast($prepared{$_})} @$order}});
    }
    confess "$context->{diagnostic} has unsupported canonical kind '$kind'\n";
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
        my ($operator, $operands) = _operator_operands($context, $node);
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

=head2 Direct default profile

C<lower_default> accepts the same arguments with C<direct_module> scope only.
It prepares immutable list/map and aggregate-operator subtrees through
C<FSM::ParameterValueSupport>, preserving packed member order and scalar
comparison results. Captured literal/static inputs determine these values;
the declaration's selected result cache is never an emission source. Nested
immutable aggregate subtrees may fold inside a scalar expression whose mutable
scalar parameter roots and dependency order remain intact.

Mutable aggregate roots, member/index selections and aggregate constructors
containing scalar parameter references refuse explicitly. Their selected
default shapes do not prove an elaborated generic layout. Static payloads
require literal leaves and complete unique map order; raw expression payloads,
foreign scopes and cyclic binding/payload trees refuse. The original
C<lower_expression> scalar and composition contracts remain unchanged. This
private entrypoint alone does not activate the direct header consumer or add a
public report schema; full external/runtime qualification remains separate.

=cut
