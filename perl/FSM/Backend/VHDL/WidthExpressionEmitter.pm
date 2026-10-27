package FSM::Backend::VHDL::WidthExpressionEmitter;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(refaddr);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::WidthExpressionSupport;
use FSM::Backend::VHDL::ParameterBindingEmitter;

sub lower_range ($class, %args) {
    my $port = $args{port};
    my $contract = $port->{width_contract};
    my $context = $args{context} // ("VHDL declared signal '" . ($port->{name} // '?') . "' width");
    confess "$context requires a complete width contract\n"
        unless ref($contract) eq 'HASH' && exists($contract->{expression})
            && ref($contract->{references}) eq 'ARRAY';
    confess "$context cannot combine a width contract with a declared type\n"
        if defined($port->{declared_type_spec}) || defined($port->{declared_type_name});
    my $environment = $args{environment};
    my $scope = ref($environment) eq 'HASH' ? $environment->{scope} : undef;
    my $scope_description = $args{scope_description} // 'source';
    confess "$context requires the matching captured $scope_description scope\n"
        unless ref($scope) eq 'HASH' && defined($scope->{kind}) && !ref($scope->{kind})
            && $scope->{kind} =~ /\A(?:direct_module|composition_top)\z/
            && defined($scope->{owner}) && !ref($scope->{owner}) && length($scope->{owner})
            && (!defined($args{required_scope_kind}) || $scope->{kind} eq $args{required_scope_kind})
            && ref($contract->{scope}) eq 'HASH'
            && ($contract->{scope}{kind} // '') eq ($scope->{kind} // '')
            && ($contract->{scope}{owner} // '') eq ($scope->{owner} // '');

    my $language = $args{target_language} // 'vhdl';
    confess "$context requires a VHDL target\n" unless !ref($language) && lc($language) eq 'vhdl';
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
        FSM::Backend::VHDL::ParameterBindingEmitter->validate_identifier($name);
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

FSM::Backend::VHDL::WidthExpressionEmitter - Shared portable scoped prepared width ranges

=head1 DESCRIPTION

C<lower_range> consumes C<port>, C<environment> and optional VHDL
C<target_language> in explicit C<direct_module> or C<composition_top> scope.
The prepared C<width_contract> contains matching C<scope>, structured
C<expression> and ordered C<references>. It returns a parenthesized descending
vector range, retaining one-bit rank and selected parameter root names.

The existing width evaluator owns integer parsing and arithmetic. Portable
natural bounds through 2147483647 apply at every intermediate step and final
width is positive. Arithmetic folds explicitly left; modulo renders as C<mod>.
Static subtrees fold through captured payloads. Selected roots reuse the
existing VHDL basic-identifier check. Numeric width caches never provide text.

Unknown/mismatched scopes, foreign targets, type conflicts, wrong/missing/extra
lookups, cycles, unsupported operators, invalid natural arithmetic and reserved
root names refuse. Caller records remain read-only; returned text retains no
caller graph. Full declaration/namespace/provenance preparation remains the
caller's obligation; this helper does not attest arbitrary caller-made hashes.

C<context>, C<scope_description> and C<required_scope_kind> preserve a narrower
wrapper's diagnostics and scope policy. Composition keeps its top boundary.
Direct captured-plan preparation, source-aware conversion, direct ranges and
complete compiler/override/runtime qualification remain separate work.

=cut
