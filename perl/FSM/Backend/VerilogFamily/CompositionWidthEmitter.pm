package FSM::Backend::VerilogFamily::CompositionWidthEmitter;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(refaddr);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::WidthExpressionSupport;
use FSM::Backend::VerilogFamily::CompositionBindingEmitter;

sub lower_range ($class, %args) {
    my $port = $args{port};
    my $contract = $port->{width_contract};
    my $context = "Composition port '" . ($port->{name} // '?') . "' width";
    confess "$context requires a complete width contract\n"
        unless ref($contract) eq 'HASH' && exists($contract->{expression})
            && ref($contract->{references}) eq 'ARRAY';
    confess "$context cannot combine a width contract with a declared type\n"
        if defined($port->{declared_type_spec}) || defined($port->{declared_type_name});
    my $environment = $args{environment};
    my $scope = ref($environment) eq 'HASH' ? $environment->{scope} : undef;
    confess "$context requires the matching captured top scope\n"
        unless ref($scope) eq 'HASH' && ref($contract->{scope}) eq 'HASH'
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
    my $state = {evaluator => $evaluator, environment => $environment,
        language => $args{target_language}, scope => $scope, active => {}, context => $context};
    my ($text, $value) = _render($state, $contract->{expression});
    confess "$context has unused width lookup records\n" unless $cursor == @$references;
    confess "$context must resolve to a positive integer width\n" unless $value->bcmp(0) > 0;
    return "[($text - 1):0] ";
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
        my $value = $evaluator->evaluate_constant_integer_scalar($expression, $context);
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
        my $rendered = FSM::Backend::VerilogFamily::CompositionBindingEmitter->lower_expression(
            environment => $state->{environment}, target_language => $state->{language},
            binding => {kind => 'parameter', scope => $state->{scope}, parameter => $name, token => $name, suffix => ''});
        my $value = $evaluator->evaluate_constant_integer_expression(['param', $name], $context);
        return ($rendered->{text}, $value, 1);
    }
    my $normalized = $evaluator->normalize_constant_width_operator($operator);
    confess "$context uses unsupported width expression operator\n" unless defined $normalized;
    @operands = @{$operands[0]} if @operands == 1 && ref($operands[0]) eq 'ARRAY';
    confess "$context width operator requires at least two operands\n" unless @operands >= 2;
    my (@texts, @values, $symbolic);
    for my $operand (@operands) {
        my ($text, $value, $has_parameter) = _render($state, $operand);
        push @texts, $text;
        push @values, $value;
        $symbolic ||= $has_parameter;
    }
    my $value = $evaluator->apply_constant_width_operator($normalized, \@values, $context);
    # Width arithmetic is a left fold; parentheses also prevent HDL precedence
    # from changing the meaning of mixed bitwise or arithmetic subexpressions.
    my $text = shift @texts;
    $text = "($text $normalized $_)" for @texts;
    return ($symbolic ? $text : $value->bstr, $value, $symbolic);
}

1;

=head1 NAME

FSM::Backend::VerilogFamily::CompositionWidthEmitter - Prepared scalar composition port ranges

=head1 DESCRIPTION

Renders captured C<width_contract> trees for the direct Verilog-family
structural emitter. Scope and ordered parameter/static lookup records must
match the actual expression. Selected parameters retain their declared names;
static integer subexpressions resolve through captured payloads. The shared
width evaluator checks nonnegative intermediates and positive final defaults.
Numeric port width caches never supply range text. A parameter-dependent range
is retained even when its default is one bit.

=head1 METHODS

=head2 lower_range

Accepts C<port>, captured C<environment> and C<target_language>, after canonical
top declaration validation. Returns a packed range and trailing space. Static
expression subtrees fold to decimal integers; symbolic operations use explicit
left-associated parentheses. Declared types combined with width contracts,
foreign scopes, missing/extra/wrong lookups, unsupported shapes, aggregates and
invalid default arithmetic refuse. Caller records remain read-only.
Source admission, override legality, nets, VHDL generics and external HDL
qualification remain separately owned; this helper does not attest caller-made
hash provenance or enable those profiles.

=cut
