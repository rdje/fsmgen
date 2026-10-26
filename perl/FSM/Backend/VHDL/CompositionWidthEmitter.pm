package FSM::Backend::VHDL::CompositionWidthEmitter;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(refaddr);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::WidthExpressionSupport;

sub lower_range ($class, %args) {
    my $port = $args{port};
    my $contract = $port->{width_contract};
    my $context = "VHDL composition port '" . ($port->{name} // '?') . "' width";
    confess "$context requires a complete width contract\n"
        unless ref($contract) eq 'HASH' && exists($contract->{expression})
            && ref($contract->{references}) eq 'ARRAY';
    confess "$context cannot combine a width contract with a declared type\n"
        if defined($port->{declared_type_spec}) || defined($port->{declared_type_name});
    my $environment = $args{environment};
    my $scope = ref($environment) eq 'HASH' ? $environment->{scope} : undef;
    confess "$context requires the matching captured top scope\n"
        unless ref($scope) eq 'HASH' && ($scope->{kind} // '') eq 'composition_top'
            && ref($contract->{scope}) eq 'HASH'
            && ($contract->{scope}{kind} // '') eq ($scope->{kind} // '')
            && ($contract->{scope}{owner} // '') eq ($scope->{owner} // '');

    my $references = $contract->{references};
    my $cursor = 0;
    my $lookup = sub ($kind, $token) {
        my $reference = $references->[$cursor++];
        confess "$context lookup sequence does not match source '$token'\n"
            unless ref($reference) eq 'HASH' && ($reference->{kind} // '') eq $kind
                && defined($reference->{token}) && !ref($reference->{token}) && $reference->{token} eq $token;
        return $reference;
    };
    my $evaluator = FSM::WidthExpressionSupport->new(
        resolve_symbol_payload => sub ($token) {
            return $lookup->('static_symbol', $token)->{value_payload};
        },
        resolve_parameter_payload => sub ($name) {
            $lookup->('parameter', $name);
            my $parameter = $environment->{parameters}{$name};
            return ref($parameter) eq 'HASH' ? $parameter->{value_payload} : undef;
        },
    );
    my $state = {evaluator => $evaluator, active => {}, context => $context};
    my ($text, $value) = _render($state, $contract->{expression});
    confess "$context has unused width lookup records\n" unless $cursor == @$references;
    confess "$context must resolve to a positive integer width\n" unless $value->bcmp(0) > 0;
    return "(($text - 1) downto 0)";
}

sub _bounded ($state, $value) {
    confess "$state->{context} is outside the portable integer range\n"
        unless defined($value) && $value->bcmp(0) >= 0 && $value->bcmp('2147483647') <= 0;
    return $value;
}

sub _unwrap_selector ($expression, $context) {
    my %seen;
    while (ref($expression) eq 'ARRAY' && @$expression == 1) {
        confess "$context has a cyclic parameter selector\n" if $seen{refaddr($expression)}++;
        $expression = $expression->[0];
    }
    return $expression;
}

sub _render ($state, $expression) {
    my $context = $state->{context};
    my $evaluator = $state->{evaluator};
    if (!ref($expression)) {
        my $value = _bounded($state, $evaluator->evaluate_constant_integer_scalar($expression, $context));
        return ($value->bstr, $value, 0);
    }
    confess "$context has a malformed width expression\n"
        unless ref($expression) eq 'ARRAY' && @$expression;
    my $identity = refaddr($expression);
    confess "$context has a cyclic width expression\n" if $state->{active}{$identity};
    local $state->{active}{$identity} = 1;
    return _render($state, $expression->[0]) if @$expression == 1;
    my ($operator, @operands) = @$expression;
    if (defined($operator) && !ref($operator) && $operator eq 'param') {
        my $name = @operands == 1 ? _unwrap_selector($operands[0], $context) : undef;
        confess "$context parameter selector requires one declared name\n"
            unless @operands == 1 && $evaluator->is_contract_identifier($name);
        # Complete VHDL declaration/namespace validation precedes this helper.
        my $value = _bounded($state, $evaluator->evaluate_constant_integer_expression(['param', $name], $context));
        return ($name, $value, 1);
    }
    my $normalized = $evaluator->normalize_constant_width_operator($operator);
    confess "$context uses unsupported width expression operator\n" unless defined($normalized) && $normalized =~ /\A[+*\/%-]\z/;
    @operands = @{$operands[0]} if @operands == 1 && ref($operands[0]) eq 'ARRAY';
    confess "$context width operator requires at least two operands\n" unless @operands >= 2;
    my (@texts, @values, $symbolic);
    for my $operand (@operands) {
        my ($text, $value, $has_parameter) = _render($state, $operand);
        push @texts, $text;
        push @values, $value;
        $symbolic ||= $has_parameter;
    }
    my $value = shift @values;
    for my $operand (@values) {
        $value = _bounded($state, $evaluator->apply_constant_width_operator($normalized, [$value, $operand], $context));
    }
    my $vhdl_operator = $normalized eq '%' ? 'mod' : $normalized;
    my $text = shift @texts;
    $text = "($text $vhdl_operator $_)" for @texts;
    return ($symbolic ? $text : $value->bstr, $value, $symbolic);
}

1;

=head1 NAME

FSM::Backend::VHDL::CompositionWidthEmitter - Prepared scalar VHDL composition port ranges

=head1 DESCRIPTION

Renders captured C<width_contract> trees after the structural emitter validates
natural top generics and the VHDL namespace. Scope and ordered parameter/static
lookups must match. Parameters retain selected names; static subexpressions
fold through the shared integer evaluator. Arithmetic C<+>, C<->, C<*>, C</>
and C<%> uses explicit left-associated parentheses; C<%> renders as C<mod>.
Each default fold fits the portable natural integer range through 2147483647;
final width must be positive. Numeric port width caches never provide range
text. Even a one-bit default retains its vector range.

=head1 METHODS

=head2 lower_range

Accepts C<port> and captured C<environment>. Returns a parenthesized descending
VHDL vector range. Declared-type conflicts, foreign scopes, incomplete or wrong
lookups, cycles, aggregates, unsupported operators and invalid default arithmetic
refuse. Inputs remain read-only. Source admission, internal nets, external
override legality and compiler/runtime qualification remain separately owned.
Caller-made hashes do not acquire provenance from this helper.

=cut
