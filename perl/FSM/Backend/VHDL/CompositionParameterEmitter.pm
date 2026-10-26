package FSM::Backend::VHDL::CompositionParameterEmitter;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(refaddr);
use JSON::PP ();
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::ParameterValueSupport;
use FSM::WidthExpressionSupport;
use FSM::Support::HDLInstanceIdentifierPolicy;

sub lower_declarations ($class, %args) {
    my $structural = $args{structural};
    confess "VHDL generic preparation requires a structural hash\n" unless ref($structural) eq 'HASH';
    confess "VHDL generic preparation requires a VHDL target\n"
        unless lc($structural->{target_language} // 'vhdl') eq 'vhdl';
    return [] unless exists $structural->{parameter_environment};
    my $environment = $structural->{parameter_environment};
    confess "VHDL generic preparation requires a resolved parameter environment\n"
        unless ref($environment) eq 'HASH' && ref($environment->{parameters}) eq 'HASH'
            && ref($environment->{declaration_order}) eq 'ARRAY';
    my $module = _identifier($structural->{module_name});
    my $scope = $environment->{scope};
    confess "VHDL generic scope must identify the actual structural module\n"
        unless ref($scope) eq 'HASH' && ($scope->{kind} // '') eq 'composition_top'
            && ($scope->{owner} // '') eq $module;
    my %reserved = (lc($module) => 'module');
    for my $bucket (['ports','name','port'], ['nets','name','net'], ['instances','instance_name','instance']) {
        my ($key,$name_key,$origin) = @$bucket;
        my $entries = $structural->{$key} // [];
        confess "VHDL generic namespace requires structural $key as an array\n" unless ref($entries) eq 'ARRAY';
        for my $entry (@$entries) {
            confess "VHDL generic namespace requires a named structural $origin\n" unless ref($entry) eq 'HASH';
            my $name = _identifier($entry->{$name_key});
            $reserved{lc($name)} //= $origin;
        }
    }
    my ($parameters,$order,$bindings) = @{$environment}{qw(parameters declaration_order default_bindings)};
    my %declared;
    for my $name (@$order) {
        _identifier($name);
        confess "VHDL generic preparation has invalid declaration order\n"
            unless exists($parameters->{$name}) && !$declared{$name}++;
        confess "VHDL generic '$name' collides with structural $reserved{lc($name)}\n"
            if exists $reserved{lc($name)};
        $reserved{lc($name)} = 'parameter';
        my $parameter = $parameters->{$name};
        confess "VHDL generic '$name' requires a scalar parameter\n"
            unless ref($parameter) eq 'HASH' && ($parameter->{value_kind} // '') eq 'scalar';
        if (exists $parameter->{value_type_spec}) {
            my $type = $parameter->{value_type_spec};
            confess "VHDL generic '$name' has an unsupported inferred scalar type\n"
                unless ref($type) eq 'HASH' && ($type->{kind} // '') =~ /\A(?:bit|bits)\z/;
        }
        _integer_payload($parameter->{value_payload});
    }
    confess "VHDL generic preparation has incomplete declaration order membership\n"
        unless keys(%declared) == keys(%$parameters);
    confess "VHDL generic preparation requires complete default binding membership\n"
        unless ref($bindings) eq 'HASH' && keys(%$bindings) == keys(%declared)
            && !grep {!exists $bindings->{$_}} @$order;
    my (%lowered,%dependencies);
    for my $name (@$order) {
        my $state = {environment=>$environment, scope=>$scope, active=>{}, references=>[]};
        my ($text) = _render($state, $bindings->{$name});
        $lowered{$name} = {name=>$name, type=>'natural', default_text=>$text,
            parameter_references=>$state->{references}};
        $dependencies{$name} = {map {$_=>1} @{$state->{references}}};
    }
    my (%emitted,@result);
    while (@result < @$order) {
        my $next;
        for my $candidate (@$order) {
            next if $emitted{$candidate} || grep {!$emitted{$_}} keys %{$dependencies{$candidate}};
            $next = $candidate; last;
        }
        confess "VHDL generic defaults contain a dependency cycle\n" unless defined $next;
        push @result, $lowered{$next}; $emitted{$next} = 1;
    }
    return \@result;
}

sub _identifier ($name) {
    confess "VHDL generic namespace requires a basic identifier\n"
        unless defined($name) && !ref($name) && $name =~ /\A[A-Za-z](?:[A-Za-z0-9]|_[A-Za-z0-9])*\z/;
    confess "VHDL generic namespace identifier '$name' is reserved\n"
        if grep {$_ eq 'VHDL'} @{FSM::Support::HDLInstanceIdentifierPolicy->reserved_target_languages($name)};
    confess "VHDL generic namespace identifier '$name' hides a generated type\n"
        if grep {lc($name) eq $_} qw(natural std_logic std_logic_vector signed);
    return $name;
}

sub lower_actual ($class, %args) {
    my $structural = $args{structural};
    $class->lower_declarations(structural => $structural);
    my $environment = $structural->{parameter_environment};
    confess "VHDL symbolic generic actual requires its captured parameter environment\n"
        unless ref($environment) eq 'HASH';
    my $override = $args{override};
    my $instance = $args{instance};
    confess "VHDL symbolic generic actual requires an instance and override record\n"
        unless ref($instance) eq 'HASH' && ref($override) eq 'HASH';
    _identifier($instance->{module_name});
    _identifier($override->{name});
    confess "VHDL symbolic generic actual requires a scalar integer child declaration\n"
        unless ($override->{value_kind} // '') eq 'scalar'
            && ($override->{declaration_default_value_kind} // '') eq 'scalar';
    my $text = $override->{declaration_default_value_text};
    my $payload = $override->{declaration_default_value_payload};
    my $type = $override->{declaration_default_value_type_spec};
    confess "VHDL symbolic generic actual requires decimal integer declaration evidence\n"
        unless defined($text) && !ref($text) && $text =~ /\A\+?\d[\d_]*\z/
            && ref($payload) eq 'HASH' && ($payload->{kind} // '') eq 'scalar'
            && defined($payload->{payload}) && !ref($payload->{payload}) && $payload->{payload} eq $text
            && ref($type) eq 'HASH';
    _integer_payload($payload);
    my $canonical = FSM::ParameterValueSupport->canonical_value(value_ast => $payload);
    my $json = JSON::PP->new->canonical;
    confess "VHDL symbolic generic actual has inconsistent declaration type evidence\n"
        unless $json->encode($type) eq $json->encode($canonical->{value_type_spec})
            && (!exists($override->{declaration_default_value_width})
                || $json->encode($override->{declaration_default_value_width}) eq $json->encode($canonical->{value_width}));
    my $state = {environment=>$environment, scope=>$environment->{scope}, active=>{}, references=>[]};
    my ($actual) = _render($state, $override->{binding_expression});
    return $actual;
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

FSM::Backend::VHDL::CompositionParameterEmitter - Prepared canonical natural-valued VHDL generics

=head1 DESCRIPTION

Prepares captured scalar top defaults and child actuals for direct VHDL
structural emission. Source admission remains separate. The bounded profile selects C<natural> generics with plain
nonnegative decimal literals, scalar aliases, captured decimal static payloads
and canonical C<+>, C<->, C<*>, C</>, C<%> arithmetic. Modulo renders as C<mod>;
explicit left-associated parentheses retain operand order. Rendered arithmetic
intermediates must be nonnegative and fit the portable integer range through
2147483647. Sized literals, bitwise operators, aggregates and explicitly typed
top profiles remain outside this preparation boundary.

=head1 METHODS

=head2 lower_declarations

Consumes C<structural> with a matching VHDL-target captured parameter environment.
Returns detached C<name>, C<type>, C<default_text> and ordered
C<parameter_references> records. Dependency order uses the earliest currently
ready authored declaration. Validation numbers check the default profile but
never replace selected names or authored defaults in emitted text.

Module, port, signal, instance and parameter names reserve a case-insensitive
namespace. Names must be non-reserved VHDL basic identifiers and cannot hide the generated
C<natural>, C<std_logic>, C<std_logic_vector> or C<signed> type names; incomplete
membership, cyclic defaults, foreign scopes and unsupported shapes refuse.
Static structural inputs return an empty array. This internal helper does not
attest the provenance of caller-made hashes, establish external override
legality or emit a module.

=head2 lower_actual

Consumes C<structural>, C<instance> and C<override>. Validates the captured
natural top environment and emits the canonical C<binding_expression> without
using the actual-value cache. The child must have scalar declaration evidence
with a bounded plain nonnegative decimal default and consistent canonical
payload/type/optional width records. Sized bit/vector and aggregate symbolic
child declarations refuse rather than acquiring guessed integer conversions.
Child module and generic names must be valid VHDL basic identifiers. Static
actuals retain the structural emitter's existing separate literal path.

=cut
