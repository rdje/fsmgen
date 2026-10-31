package FSM::Backend::VerilogFamily::WidthExpressionEmitter;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(refaddr);
use bytes ();
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::WidthExpressionSupport;
use FSM::Backend::VerilogFamily::ParameterBindingEmitter;

sub lower_range ($class, %args) {
    my ($text) = _lower_expression(%args);
    return "[($text - 1):0] ";
}

sub _lower_expression (%args) {
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
    my ($text, $value, $symbolic) = _render($state, $contract->{expression});
    confess "$context has unused width lookup records\n" unless $cursor == @$references;
    confess "$context must resolve to a positive integer width\n" unless $value->bcmp(0) > 0;
    return ($text, $value, $symbolic);
}

# Validate each independent contract before composition. Equal selected defaults
# never establish a relationship between operands or supply symbolic authority.
sub _prepared_terms (%args) {
    my $context = $args{context};
    my $operands = $args{operands};
    confess "$context requires between one and 32 width operands\n"
        unless ref($operands) eq 'ARRAY' && @$operands && @$operands <= 32;
    my $budget = {nodes => 4096, bytes => 131072, active => {}, context => $context};
    _prepared_input($budget, [$operands, $args{environment}], 0);
    my @terms;
    for my $operand (@$operands) {
        confess "$context requires positive decimal widths and optional prepared contracts\n"
            unless ref($operand) eq 'HASH' && exists($operand->{width})
                && !grep {$_ ne 'width' && $_ ne 'width_contract'} keys %$operand;
        my $width = $operand->{width};
        confess "$context requires a positive decimal observed width\n"
            unless defined($width) && !ref($width) && $width =~ /\A[1-9][0-9]*\z/;
        my $contract = $operand->{width_contract};
        $contract //= {scope => ref($args{environment}) eq 'HASH' ? $args{environment}{scope} : undef,
            expression => $width, references => []};
        my ($text, $value, $symbolic) = _lower_expression(%args,
            context => $context, port => {width_contract => $contract});
        confess "$context disagrees with an independently observed operand width\n"
            unless $value->bcmp($width) == 0;
        push @terms, {text => $text, value => $value, symbolic => $symbolic};
    }
    return @terms;
}

sub lower_sum_range ($class, %args) {
    my $context = $args{context} // 'Prepared sum width';
    my @terms = _prepared_terms(%args, context => $context);
    my $value = FSM::WidthExpressionSupport->new->apply_constant_width_operator(
        '+', [map {$_->{value}} @terms], $context);
    my $symbolic = grep {$_->{symbolic}} @terms;
    my $text = shift(@terms)->{text};
    $text = "($text + $_->{text})" for @terms;
    $text = $value->bstr unless $symbolic;
    my $range = "[($text - 1):0] ";
    confess "$context exceeds bounded rendered width text\n" if bytes::length($range) > 32768;
    return $range;
}

sub lower_maximum_range ($class, %args) {
    my $context = $args{context} // 'Prepared maximum width';
    my @terms = _prepared_terms(%args, context => $context);
    # Pairwise reduction bounds repeated conditional text quadratically instead
    # of duplicating the entire preceding maximum at each additional operand.
    while (@terms > 1) {
        my @next;
        while (@terms) {
            my $left = shift @terms;
            my $right = shift @terms;
            unless ($right) {push @next, $left; next}
            my $value = $left->{value}->bcmp($right->{value}) > 0 ? $left->{value} : $right->{value};
            my $symbolic = $left->{symbolic} || $right->{symbolic};
            my $text = $symbolic
                ? "($left->{text} > $right->{text} ? $left->{text} : $right->{text})" : $value->bstr;
            confess "$context exceeds bounded rendered width text\n" if bytes::length($text) > 32768;
            push @next, {text => $text, value => $value, symbolic => $symbolic};
        }
        @terms = @next;
    }
    my $range = "[($terms[0]{text} - 1):0] ";
    confess "$context exceeds bounded rendered width text\n" if bytes::length($range) > 32768;
    return $range;
}

sub _prepared_input ($state, $node, $depth) {
    my $context = $state->{context};
    confess "$context exceeds its bounded prepared width inputs\n"
        if $depth > 32 || --$state->{nodes} < 0;
    unless (ref($node)) {
        my $bytes = defined($node) ? bytes::length($node) : 0;
        $state->{bytes} -= $bytes;
        confess "$context exceeds its bounded prepared width inputs\n"
            if $bytes > 4096 || $state->{bytes} < 0;
        return;
    }
    confess "$context requires plain acyclic prepared width inputs\n"
        unless ref($node) eq 'ARRAY' || ref($node) eq 'HASH';
    my $identity = refaddr($node);
    confess "$context has cyclic prepared width inputs\n" if $state->{active}{$identity};
    local $state->{active}{$identity} = 1;
    if (ref($node) eq 'ARRAY') {
        _prepared_input($state, $_, $depth + 1) for @$node;
    } else {
        for my $key (sort keys %$node) {
            _prepared_input($state, $key, $depth + 1);
            _prepared_input($state, $node->{$key}, $depth + 1);
        }
    }
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

C<lower_maximum_range> composes C<operands>, a nonempty array of at most
32 records containing a positive decimal observed C<width> and an optional
C<width_contract>, with the same C<environment>, target and scope arguments.
Each contract uses the existing renderer, exact ordered lookups and arithmetic
checks; its selected value must equal that operand's observed width, including
branches dominated by a larger default. An absent contract is an independent
fixed floor. Mutable branches always remain in the target conditional maximum,
even at default one or when their defaults agree. Fixed-only subtrees fold.
The result is always a packed range, including a one-bit maximum.

C<lower_sum_range> takes the same arguments and independently checked operands.
It composes an ordered left-fold addition, preserving repeated slots and each
independent mutable contract regardless of its selected default. Fixed operands
are exact summands rather than floors; fixed-only sums fold through the canonical
integer arithmetic. A single operand still returns a packed range at width one.
It neither selects literal sizing nor proves current source/allocation identity.

The complete operand/environment input is limited to 4,096 occurrences,
32 traversal levels, 4,096 bytes per scalar and 131,072 scalar bytes in total.
Cycles and non-plain containers refuse. Balanced pairwise conditional composition
limits maximum duplication; sums render each ordered operand once. Rendered range
text is capped at 32,768 bytes. Exceeding a
bound refuses without a default-sized fallback. No new source arithmetic
operator, text parsing or parameter-dependency reconstruction is introduced.
This method renders supplied prepared contracts; it does not attest actual
source membership, literal sizing, selected declarations or emitted ledgers.

C<context>, C<scope_description> and C<required_scope_kind> let a narrower wrapper
retain its diagnostic and scope policy. The composition wrapper keeps its top
boundary. Canonical declaration/name/provenance preparation remains the caller's
obligation. Direct captured-source/target preparation now supplies these
contracts to direct port emission. This kernel alone neither attests capture
authorship nor changes source/report schemas. Storage/computed shapes and full
compiler/override/runtime qualification remain separately owned.

=cut
