package FSM::Backend::VHDL::ParameterBindingEmitter;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(refaddr);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::ParameterValueSupport;
use FSM::WidthExpressionSupport;
use FSM::Support::HDLInstanceIdentifierPolicy;

sub lower_expression ($class, %args) {
    my $language = $args{target_language} // 'vhdl';
    confess "VHDL generic renderer requires a VHDL target\n"
        unless !ref($language) && lc($language) eq 'vhdl';
    my $environment = $args{environment};
    confess "VHDL generic renderer requires a resolved environment\n"
        unless ref($environment) eq 'HASH' && ref($environment->{parameters}) eq 'HASH'
            && ref($environment->{declaration_order}) eq 'ARRAY';
    my $scope = $environment->{scope};
    confess "VHDL generic renderer requires an explicit direct-module or composition-top scope\n"
        unless ref($scope) eq 'HASH' && defined($scope->{kind}) && !ref($scope->{kind})
            && $scope->{kind} =~ /\A(?:direct_module|composition_top)\z/
            && defined($scope->{owner}) && !ref($scope->{owner}) && length($scope->{owner});
    my %declared;
    for my $name (@{$environment->{declaration_order}}) {
        _identifier($name);
        confess "VHDL generic renderer has invalid declaration order\n"
            unless exists($environment->{parameters}{$name}) && !$declared{$name}++;
    }
    confess "VHDL generic renderer has incomplete declaration order membership\n"
        unless keys(%declared) == keys(%{$environment->{parameters}});
    my $state = {environment=>$environment, scope=>$scope, active=>{}, references=>[]};
    my ($text) = _render($state, $args{binding});
    return {text=>$text, parameter_references=>$state->{references}};
}

sub validate_identifier ($class, $name) { return _identifier($name) }
sub validate_integer_payload ($class, $payload) { return _integer_payload($payload) }

sub _identifier ($name) {
    confess "VHDL generic namespace requires a basic identifier\n"
        unless defined($name) && !ref($name) && $name =~ /\A[A-Za-z](?:[A-Za-z0-9]|_[A-Za-z0-9])*\z/;
    confess "VHDL generic namespace identifier '$name' is reserved\n"
        if grep {$_ eq 'VHDL'} @{FSM::Support::HDLInstanceIdentifierPolicy->reserved_target_languages($name)};
    confess "VHDL generic namespace identifier '$name' hides a generated type\n"
        if grep {lc($name) eq $_} qw(natural std_logic std_logic_vector signed);
    return $name;
}

sub _bounded_natural ($value) {
    confess "VHDL natural generic default is outside the portable integer range\n"
        unless defined($value) && $value->bcmp(0) >= 0 && $value->bcmp('2147483647') <= 0;
    return $value;
}

sub _integer_payload ($payload) {
    confess "VHDL natural generic requires a decimal scalar payload\n"
        unless ref($payload) eq 'HASH' && ($payload->{kind} // '') =~ /\A(?:scalar|scalar_expr)\z/
            && defined($payload->{payload}) && !ref($payload->{payload})
            && $payload->{payload} =~ /\A[0-9_\s()+*\/%-]+\z/;
    return _bounded_natural(FSM::WidthExpressionSupport->new->evaluate_constant_integer_payload(
        $payload, 'VHDL natural generic payload'));
}

sub _assert_scope ($state, $scope) {
    confess "VHDL generic binding has a foreign or missing scope\n"
        unless ref($scope) eq 'HASH' && ($scope->{kind} // '') eq $state->{scope}{kind}
            && ($scope->{owner} // '') eq $state->{scope}{owner};
}

sub _render ($state, $node) {
    confess "VHDL generic renderer requires a canonical binding node\n" unless ref($node) eq 'HASH';
    my $identity = refaddr($node);
    confess "VHDL generic binding contains a cyclic tree\n" if $state->{active}{$identity};
    local $state->{active}{$identity} = 1;
    my $kind = $node->{kind} // '';
    if ($kind eq 'literal') {
        confess "VHDL natural generic requires a plain nonnegative decimal source literal\n"
            unless defined($node->{token}) && !ref($node->{token}) && $node->{token} =~ /\A\+?\d[\d_]*\z/;
        my $value = _bounded_natural(FSM::WidthExpressionSupport->new->parse_constant_integer_literal($node->{token}));
        return ($value->bstr, $value);
    }
    if ($kind eq 'parameter') {
        _assert_scope($state, $node->{scope});
        my $name = _identifier($node->{parameter});
        confess "VHDL generic binding requires an actual declared parameter\n"
            unless exists $state->{environment}{parameters}{$name};
        confess "VHDL generic binding requires an exact scalar parameter token\n"
            unless defined($node->{token}) && !ref($node->{token}) && $node->{token} eq $name
                && defined($node->{suffix}) && !ref($node->{suffix}) && $node->{suffix} eq '';
        my $value = _integer_payload($state->{environment}{parameters}{$name}{value_payload});
        push @{$state->{references}}, $name;
        return ($name, $value);
    }
    if ($kind eq 'static_symbol') {
        _assert_scope($state, $node->{scope});
        confess "VHDL generic static binding requires a source token\n"
            unless defined($node->{token}) && !ref($node->{token}) && length($node->{token});
        my $value = _integer_payload($node->{value_payload});
        return ($value->bstr, $value);
    }
    if ($kind eq 'payload') {
        my $value = _integer_payload($node->{value});
        return ($value->bstr, $value);
    }
    if ($kind eq 'operator') {
        my $operator = FSM::ParameterValueSupport->normalize_expression_operator($node->{operator});
        my $source = FSM::ParameterValueSupport->normalize_expression_operator($node->{source_operator});
        confess "VHDL natural generic requires a canonical arithmetic operator and matching source alias\n"
            unless defined($operator) && defined($source) && $operator eq $node->{operator}
                && $source eq $operator && $operator =~ /\A[+*\/%-]\z/;
        confess "VHDL natural generic operator requires at least two operands\n"
            unless ref($node->{operands}) eq 'ARRAY' && @{$node->{operands}} >= 2;
        my (@texts,@values);
        for my $operand (@{$node->{operands}}) {
            my ($text,$value) = _render($state, $operand);
            push @texts,$text; push @values,$value;
        }
        my $value = shift @values;
        for my $operand (@values) {
            $value = _bounded_natural(FSM::WidthExpressionSupport->new->apply_constant_width_operator(
                $operator, [$value, $operand], 'VHDL natural generic default'));
        }
        my $text = shift @texts;
        my $vhdl_operator = $operator eq '%' ? 'mod' : $operator;
        $text = "($text $vhdl_operator $_)" for @texts;
        return ($text,$value);
    }
    confess "VHDL natural generic has unsupported binding kind '$kind'\n";
}

1;

=head1 NAME

FSM::Backend::VHDL::ParameterBindingEmitter - Shared canonical natural-valued VHDL binding rendering

=head1 DESCRIPTION

C<lower_expression> consumes C<binding>, an explicit C<direct_module> or
C<composition_top> C<environment> and a VHDL C<target_language>. The environment
requires a source owner, complete unique C<declaration_order> and declared
C<parameters>. It returns fresh C<text> and ordered C<parameter_references>,
including repeated occurrences. The owner is lexical source identity, never an
inferred physical module name.

C<text> retains the original scalar kind for target interpolation; decimal
values may serialize as JSON numbers. This private preparation result does
not introduce a public string-valued serialization contract.

Plain nonnegative decimal literals, scalar parameter roots, captured decimal
static values and canonical arithmetic retain the existing natural-generic
profile. Modulo renders as C<mod>; explicit left-associated parentheses retain
operand order. Validation reuses C<FSM::WidthExpressionSupport> and requires
nonnegative portable integers through 2147483647 at every arithmetic step.
Validation-cache numbers never replace mutable names or captured defaults.

C<validate_identifier> and C<validate_integer_payload> expose the same internal
identifier and integer checks to declaration/actual preparers; the latter
returns a fresh validated integer object. Sized/bitwise/aggregate/path profiles,
foreign scopes, incomplete membership and recursive trees refuse. Caller input
records remain read-only and returned references are detached.

The composition wrapper retains its narrower scope, structural namespace,
declaration ordering and child-declaration checks. This helper alone does not
admit direct VHDL source profiles, implement ranges or integrate the converter;
complete external/runtime qualification remains separate.

=cut
