package FSM::Backend::VerilogFamily::WidthExpressionEmitter;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(refaddr);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::WidthExpressionSupport;
use FSM::Backend::VerilogFamily::ParameterBindingEmitter;

sub lower_range ($class, %args) {
    my $port = $args{port};
    my $contract = $port->{width_contract};
    my $context = $args{context} // ("Declared signal '" . ($port->{name} // '?') . "' width");
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

    my $language = $args{target_language} // 'systemverilog';
    confess "$context requires a Verilog-family target\n"
        unless !ref($language) && $language =~ /\A(?:systemverilog|sv|verilog|v)\z/;
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
        language => $language, scope => $scope, active => {}, context => $context};
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
        my $rendered = FSM::Backend::VerilogFamily::ParameterBindingEmitter->lower_expression(
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

FSM::Backend::VerilogFamily::WidthExpressionEmitter - Shared scoped prepared width ranges

=head1 DESCRIPTION

C<lower_range> consumes C<port>, C<environment> and C<target_language> for
explicit C<direct_module> or C<composition_top> scope. The prepared
C<width_contract> contains matching C<scope>, structured C<expression> and
ordered C<references>. Selected parameter roots render through the shared
L<FSM::Backend::VerilogFamily::ParameterBindingEmitter>; static payloads and
arithmetic reuse L<FSM::WidthExpressionSupport>. No source parsing or second
width evaluator is introduced.

Returns a packed range and trailing space. Explicit left folds preserve operand
order; static subtrees fold to decimal integers, and positive one-bit defaults
retain vector rank. Numeric width caches never supply text. Width/type conflicts,
foreign or unknown scopes, wrong/missing/unused lookups, unsupported shapes,
cycles, invalid arithmetic and foreign targets refuse without numeric fallback.
Caller inputs remain read-only and returned text retains no caller graph.

C<context>, C<scope_description> and C<required_scope_kind> let a narrower wrapper
retain its diagnostic and scope policy. The composition wrapper keeps its top
boundary. Canonical declaration/name/provenance preparation remains the caller's
obligation. Direct captured-source/target preparation now supplies these
contracts to direct port emission. This kernel alone neither attests capture
authorship nor changes source/report schemas. Storage/computed shapes and full
compiler/override/runtime qualification remain separately owned.

=cut
